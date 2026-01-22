import * as dotenv from "dotenv";
import {runNcrReminderJob} from "./jobs/ncrReminderJob";

// Load environment variables from .env for local testing
dotenv.config();

async function testNcrJob() {
  console.log("=== Running NCR Reminder Job Test ===");

  try {
    await runNcrReminderJob();
    console.log("=== Test Complete ===");
  } catch (error) {
    console.error("Error running NCR job:", error);
  }
}

// Run the test immediately
testNcrJob();
