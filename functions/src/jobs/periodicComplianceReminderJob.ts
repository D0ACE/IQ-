import * as admin from "firebase-admin";
import moment from "moment";
import {sendEmail} from "../utils/sendEmail";
import {daysDiff} from "../utils/dateUtils";
import {
  complianceReminderTemplate,
  complianceEscalationTemplate,
} from "../templates/periodicComplianceTemplates";

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
    const dueDateObject = task.dueDate.toDate();
    const dueDateString = moment(dueDateObject).format("DD-MM-YYYY");
    const diff = daysDiff(dueDateString);

    // Reminder rules: 30, 15, and every day <= 7 (including overdue diff < 0)
    const shouldSend = diff === 30 || diff === 15 || diff <= 7;

    if (shouldSend) {
      console.log(`Sending reminder for task: ${task.title}, diff: ${diff}`);

      const recipients: string[] = [];

      let lowerPersonEmail = task.assignedCustomerLowLevelEmail;
      let mediumPersonEmail = task.assignedCustomerMediumLevelEmail;
      let topLevelEmail = task.assignedCustomerTopLevelEmail;
      let consultantEmail = "";
      let consultantId = task.consultantId || task.consultant_id;

      if (task.assignedCustomerId) {
        const customerSnap = await db.collection("customers").doc(task.assignedCustomerId).get();
        if (customerSnap.exists) {
          const customerData = customerSnap.data();

          if (!consultantId) {
            consultantId = customerData?.consultantId || customerData?.consultant_id;
          }

          // Lower Person Email
          const custLowEmail = customerData?.lowLevelEmail ||
            customerData?.low_level_email ||
            customerData?.lowLevelDepartment?.email;

          if (custLowEmail) {
            lowerPersonEmail = custLowEmail;
          } else if (!lowerPersonEmail && customerData?.email) {
            lowerPersonEmail = customerData.email;
          }

          // Medium Person Email
          const custMedEmail = customerData?.mediumLevelEmail ||
            customerData?.medium_level_email ||
            customerData?.mediumLevelDepartment?.email;

          if (custMedEmail) {
            mediumPersonEmail = custMedEmail;
          }

          // Top Level Email
          const custTopEmail = customerData?.topLevelEmail ||
            customerData?.top_level_email ||
            customerData?.topLevelDepartment?.email;

          if (custTopEmail) {
            topLevelEmail = custTopEmail;
          }
        }
      }

      if (consultantId) {
        const consultantSnap = await db.collection("users").doc(consultantId).get();
        if (consultantSnap.exists) {
          consultantEmail = consultantSnap.data()?.email || "";
        }
      }

      if (diff > 0) {
        // Before due date (30, 15, 7..1 days): send to lower person
        if (lowerPersonEmail) recipients.push(lowerPersonEmail);
        if (consultantEmail) recipients.push(consultantEmail);
      } else if (diff === 0) {
        // On due date: send to lower person, medium person, and consultant
        if (lowerPersonEmail) recipients.push(lowerPersonEmail);
        if (mediumPersonEmail) recipients.push(mediumPersonEmail);
        if (consultantEmail) recipients.push(consultantEmail);
      } else if (diff < 0) {
        // Overdue (due date passed, e.g. -1, -2...): send to medium and top level persons, lower person, and consultant
        if (mediumPersonEmail) recipients.push(mediumPersonEmail);
        if (topLevelEmail) recipients.push(topLevelEmail);
        if (lowerPersonEmail) recipients.push(lowerPersonEmail);
        if (consultantEmail) recipients.push(consultantEmail);
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

      const {subject, htmlContent} = diff < 0
        ? complianceEscalationTemplate(task.title, dueDateString, task.description)
        : complianceReminderTemplate(task.title, dueDateString, task.description);

      for (const email of uniqueRecipients) {
        try {
          await sendEmail(email, subject, htmlContent);
          console.log(`Email sent to ${email} for task ${task.title} (diff: ${diff})`);
        } catch (error) {
          console.error(`Failed to send email to ${email}:`, error);
        }
      }
    }
  }

  console.log("Periodic compliance reminder job completed");
}
