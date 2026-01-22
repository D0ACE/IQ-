import * as admin from "firebase-admin";
import {sendEmail} from "../utils/sendEmail";
import {daysDiff} from "../utils/dateUtils";
import {
  lowLevelReminder,
  mediumLevelEscalation,
  topLevelCriticalEscalation,
} from "../templates/ncrEmailTemplates";
import * as path from "path"; // <-- Add this

function getDb() {
  if (admin.apps.length === 0) {
    //admin.initializeApp();
      // Use service account locally
              const serviceAccountPath = path.resolve(__dirname, "../../serviceAccountKey.json");
                 admin.initializeApp({
                   credential: admin.credential.cert(serviceAccountPath),
                 });

  }
  return admin.firestore();
}

export async function runNcrReminderJob() {
  console.log("NCR reminder job started");

  const db = getDb();

  const snapshot = await db
    .collection("ncr_forms")
    .where("status", "==", "in_progress")
    .get();

  for (const doc of snapshot.docs) {
    const ncr = doc.data();
    const diff = daysDiff(ncr.dueDate);

    const customerSnap = await db
      .collection("customers")
      .doc(ncr.customerId)
      .get();

    if (!customerSnap.exists) {
      continue;
    }

    const customer = customerSnap.data()!;

    console.log(
      "NCR date check",
      {
        dueDate: ncr.dueDate,
        diff,
        lowLevel: [7, 2, 0].includes(diff),
      }
    );

    // LOW LEVEL
    if ([7, 2, 0].includes(diff)) {
      console.log(
        "LOW LEVEL: Sending email",
        {
          email: customer.lowLevelDepartment.email,
          diff,
        }
      );

      const {subject, htmlContent} =
        lowLevelReminder(ncr.dueDate);

      await sendEmail(
        customer.lowLevelDepartment.email,
        subject,
        htmlContent
      );
    }

    // MEDIUM LEVEL
    if ([0, -3].includes(diff)) {
      console.log(
        "MEDIUM LEVEL: Sending email",
        {
          email: customer.mediumLevelDepartment.email,
          diff,
        }
      );

      const {subject, htmlContent} =
        mediumLevelEscalation(ncr.dueDate);

      await sendEmail(
        customer.mediumLevelDepartment.email,
        subject,
        htmlContent
      );
    }

    // TOP LEVEL
    if ([-3, -4].includes(diff)) {
      console.log(
        "TOP LEVEL: Sending email",
        {
          email: customer.topLevelDepartment.email,
          diff,
        }
      );

      const {subject, htmlContent} =
        topLevelCriticalEscalation(ncr.dueDate);

      await sendEmail(
        customer.topLevelDepartment.email,
        subject,
        htmlContent
      );
    }
  }

  console.log("NCR reminder job completed");
}
