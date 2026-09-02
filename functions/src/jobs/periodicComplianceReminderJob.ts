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

      // 1. Get Customer Email
      if (task.assignedCustomerId) {
        const customerSnap = await db.collection("customers").doc(task.assignedCustomerId).get();
        if (customerSnap.exists) {
          const customerData = customerSnap.data();
          if (customerData?.email) recipients.push(customerData.email);
        }
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
