import * as admin from "firebase-admin";
admin.initializeApp(); // MUST be first
import {onSchedule} from "firebase-functions/v2/scheduler";
import {runNcrReminderJob} from "./jobs/ncrReminderJob";


export const ncrDailyReminder = onSchedule(
  {
    schedule: "every day 01:00", // 01:00 AM in 24-hour format
    timeZone: "Asia/Kolkata", // Indian Standard Time
  },
  async () => {
    await runNcrReminderJob();
  }
);
