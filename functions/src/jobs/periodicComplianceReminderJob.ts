import * as admin from "firebase-admin";
import moment from "moment";
import {sendEmail} from "../utils/sendEmail";
import {daysDiff} from "../utils/dateUtils";
import {complianceReminderTemplate} from "../templates/periodicComplianceTemplates";

function getDb() {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  return admin.firestore();
}

export async function runPeriodicComplianceReminderJob() {
  console.log("Periodic compliance reminder job started");
  const db = getDb();

  const snapshot = await db
    .collection("periodic_compliance_tasks")
    .where("status", "==", "pending")
    .get();

  for (const doc of snapshot.docs) {
    const task = doc.data();
    if (!task.dueDate) continue;

    // Convert Firestore Timestamp to DD-MM-YYYY string for daysDiff utility
    // Firestone Timestamp has a toDate() method
    const dueDateObject = task.dueDate.toDate();
    const dueDateString = moment(dueDateObject).format("DD-MM-YYYY");
    const diff = daysDiff(dueDateString);

    // Reminder rules: 30, 15, 7, and every day < 7 until 0
    const shouldSend = diff === 30 || diff === 15 || (diff <= 7 && diff >= 0);

    if (shouldSend) {
      console.log(`Sending reminder for task: ${task.title}, diff: ${diff}`);

      const recipients: string[] = [];

      // 1. Get Lower & Medium Person Emails of Customer
      let lowerPersonEmail = task.assignedCustomerLowLevelEmail;
      let mediumPersonEmail = task.assignedCustomerMediumLevelEmail;

      if (task.assignedCustomerId) {
        const customerSnap = await db.collection("customers").doc(task.assignedCustomerId).get();
        if (customerSnap.exists) {
          const customerData = customerSnap.data();

          // Lower Person Email
          const custLowEmail = customerData?.lowLevelEmail ||
            customerData?.low_level_email ||
            customerData?.lowLevelDepartment?.email;

          if (custLowEmail) {
            lowerPersonEmail = custLowEmail;
          } else if (!lowerPersonEmail && customerData?.email) {
            // Fallback to main customer email if lower person email is not available
            lowerPersonEmail = customerData.email;
          }

          // Medium Person Email
          const custMedEmail = customerData?.mediumLevelEmail ||
            customerData?.medium_level_email ||
            customerData?.mediumLevelDepartment?.email;

          if (custMedEmail) {
            mediumPersonEmail = custMedEmail;
          }
        }
      }

      if (lowerPersonEmail) {
        recipients.push(lowerPersonEmail);
      }

      // On due date (diff === 0), send reminder email to medium person as well
      if (diff === 0 && mediumPersonEmail) {
        recipients.push(mediumPersonEmail);
      }

      // 2. Get Creator Email
      if (task.createdBy) {
        const creatorSnap = await db.collection("users").doc(task.createdBy).get();
        if (creatorSnap.exists) {
          const creatorData = creatorSnap.data();
          if (creatorData?.email) recipients.push(creatorData.email);
        }
      }

      // Deduplicate emails
      const uniqueRecipients = Array.from(new Set(recipients));

      const {subject, htmlContent} = complianceReminderTemplate(task.title, dueDateString);

      for (const email of uniqueRecipients) {
        try {
          await sendEmail(email, subject, htmlContent);
          console.log(`Email sent to ${email} for task ${task.title}`);
        } catch (error) {
          console.error(`Failed to send email to ${email}:`, error);
        }
      }
    }
  }

  console.log("Periodic compliance reminder job completed");
}
