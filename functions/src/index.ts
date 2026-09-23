import * as admin from "firebase-admin";
admin.initializeApp();

import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import cors from "cors";

/* =============================================================================
   LAZY INITIALIZATION HELPERS
============================================================================= */

/*
let AWS: any;
const getAwsSdk = () => {
  if (!AWS) {
    AWS = require("aws-sdk");
    AWS.config.update({
      accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
      region: process.env.AWS_REGION!,
    });
  }
  return AWS;
};

const getS3 = () => new (getAwsSdk().S3)();
const getEc2 = () => new (getAwsSdk().EC2)({region: "us-east-1"});
const getIam = () => new (getAwsSdk().IAM)();
const getCloudFront = () => new (getAwsSdk().CloudFront)();
const getCostExplorer = () => new (getAwsSdk().CostExplorer)({
  region: "us-east-1",
});
*/

const corsHandler = cors({origin: true});

/* =======================
   NCR Scheduled Job
======================= */
export const ncrDailyReminder = onSchedule(
  {
    schedule: "every day 01:00",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const {runNcrReminderJob} = require("./jobs/ncrReminderJob");
    await runNcrReminderJob();
  }
);

/* =======================
   Periodic Compliance Scheduled Job
======================= */
export const periodicComplianceDailyReminder = onSchedule(
  {
    schedule: "every day 01:30",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const {runPeriodicComplianceReminderJob} = require("./jobs/periodicComplianceReminderJob");
    await runPeriodicComplianceReminderJob();
  }
);

/* =======================
   ANNUAL DOCUMENT REVIEW
======================= */
export const annualDocumentReviewTask = onSchedule(
  {
    schedule: "every day 02:00",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const {BrevoEmailService} = require("./services/BrevoEmailService");
    const db = admin.firestore();
    const now = new Date();
    // 🚀 Check ALL documents for anniversary
    const docsSnapshot = await db.collection("documents").get();

    for (const doc of docsSnapshot.docs) {
      const data = doc.data();
      const createdAt = data.created_at?.toDate();
      if (!createdAt) continue;

      // 1. Anniversary Check (Same day/month, different year)
      const isAnniversary =
        now.getMonth() === createdAt.getMonth() &&
        now.getDate() === createdAt.getDate() &&
        now.getFullYear() > createdAt.getFullYear();

      if (isAnniversary) {
        const historyRef = doc.ref.collection("version_history");

        // 🛡️ 2. Idempotency Check: Don't run twice on the same anniversary day
        const todayStart = new Date(
          now.getFullYear(), now.getMonth(), now.getDate()
        );
        const existingReview = await historyRef
          .where("changeDescription", "==",
                 "Annual Compliance Review")
          .where("performedDate", ">=", todayStart)
          .limit(1)
          .get();

        if (!existingReview.empty) {
          continue; // Already reviewed today
        }

        const historySnapshot = await historyRef
          .orderBy("performedDate", "desc")
          .limit(1)
          .get();

        let lastVersion = data.current_version || "V1";
        if (!historySnapshot.empty) {
          lastVersion = historySnapshot.docs[0].data().versionNo || "V1";
        }

        const parts = lastVersion.substring(1).split(".");
        const major = parts[0];
        const minor = parts.length > 1 ? parseInt(parts[1]) : 0;
        const nextVersion = `V${major}.${minor + 1}`;

        // 3. Log History
        await historyRef.add({
          docId: doc.id,
          versionNo: nextVersion,
          changeDescription: "Annual Compliance Review",
          performedBy: "System (Auto-Review)",
          performedDate: admin.firestore.FieldValue.serverTimestamp(),
          status: data.status,
          docTitle: data.title || "Untitled Document",
        });

        // 4. Update Main Doc
        await doc.ref.update({
          current_version: nextVersion,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 5. Send Notification
        if (data.customer_id) {
          const customerDoc = await db.collection("customers")
            .doc(data.customer_id)
            .get();
          const customerData = customerDoc.data();
          if (customerData && customerData.email) {
            await BrevoEmailService.sendReviewRequest(
              customerData.email,
              customerData.companyName || "Customer",
              data.title || "Untitled Document"
            );
          }
        }
      }
    }
  }
);

/* =======================
   LIST ALL AWS RESOURCES (COMMENTED OUT)
======================= */
/*
export const listAllAwsResources = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    try {
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      const s3 = getS3();
      const ec2 = getEc2();
      const iam = getIam();
      const cloudFront = getCloudFront();

      const s3BucketsRes = await s3.listBuckets().promise();
      const s3Buckets = await Promise.all(
        (s3BucketsRes.Buckets || []).map(async (bucket: any) => {
          const bucketName = bucket.Name!;
          const loc = await s3
            .getBucketLocation({Bucket: bucketName})
            .promise();
          const ver = await s3
            .getBucketVersioning({Bucket: bucketName})
            .promise();
          return {
            name: bucketName,
            createdAt: bucket.CreationDate,
            region: loc.LocationConstraint || "us-east-1",
            versioning: ver.Status || "Disabled",
          };
        })
      );

      const ec2Data = await ec2.describeInstances().promise();
      const ec2Instances = ec2Data.Reservations?.flatMap((r: any) =>
        (r.Instances || []).map((i: any) => ({
          instanceId: i.InstanceId,
          name: i.Tags?.find((t: any) => t.Key === "Name")?.Value || "N/A",
          state: i.State?.Name,
          instanceType: i.InstanceType,
        }))
      ) || [];

      const iamUsersRes = await iam.listUsers().promise();
      const iamUsers = iamUsersRes.Users.map((u: any) => ({
        userName: u.UserName,
        arn: u.Arn,
      }));

      const cfRes = await cloudFront.listDistributions().promise();
      const cfList = cfRes.DistributionList?.Items || [];

      res.status(200).json({
        region: "us-east-1",
        summary: {
          s3Buckets: s3Buckets.length,
          ec2Instances: ec2Instances.length,
          iamUsers: iamUsers.length,
          cloudFrontDistributions: cfList.length,
        },
        details: {
          s3: s3Buckets,
          ec2: ec2Instances,
          iam: iamUsers,
          cloudFront: cfList,
        },
      });
    } catch (error: any) {
      console.error("AWS RESOURCE ERROR:", error);
      res.status(500).json({error: "Failed to fetch AWS resources"});
    }
  });
});
*/

/* =======================
   DAILY BILLING SCHEDULER (COMMENTED OUT)
======================= */
/*
export const storeAwsBillingDaily = onSchedule(
  {
    schedule: "every day 01:00",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    try {
      const costExp = getCostExplorer();
      const today = new Date();
      const start = new Date(today.getFullYear(), today.getMonth(), 1)
        .toISOString().split("T")[0];
      const end = today.toISOString().split("T")[0];

      const billingRes = await costExp.getCostAndUsage({
        TimePeriod: {Start: start, End: end},
        Granularity: "MONTHLY",
        Metrics: ["UnblendedCost"],
        GroupBy: [{Type: "DIMENSION", Key: "SERVICE"}],
      }).promise();

      const billing = billingRes.ResultsByTime?.[0].Groups?.map((g: any) => ({
        service: g.Keys?.[0],
        amount: Number(g.Metrics?.UnblendedCost?.Amount || 0),
        unit: g.Metrics?.UnblendedCost?.Unit,
      })) || [];

      const billingCollection = admin.firestore()
        .collection("aws_billing_daily");
      const snap = await billingCollection.get();
      const batch = admin.firestore().batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();

      await billingCollection.add({
        billing,
        region: "us-east-1",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log("✅ AWS billing stored");
    } catch (error) {
      console.error("❌ AWS Billing Scheduler Error:", error);
    }
  }
);
*/

/* =============================================================================
   BREVO EMAIL DISPATCHER (Option 1: Firebase Proxy)
============================================================================= */
export const triggerBrevoEmail = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    try {
      // 1. Basic Security: Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({error: "Method Not Allowed"});
        return;
      }

      const {templateId, to, toName, params} = req.body;

      // 2. Validation
      if (!templateId || !to || !toName) {
        res.status(400).json({error: "Missing required fields"});
        return;
      }

      const {BrevoEmailService} = require("./services/BrevoEmailService");

      // 3. Dispatch Email via Brevo (from a fixed Google/Firebase IP)
      await BrevoEmailService.sendTemplateEmail(
        Number(templateId),
        to,
        toName,
        params || {}
      );

      res.status(200).json({message: "Email dispatched successfully"});
    } catch (error: any) {
      console.error("🔥 BREVO TRIGGER ERROR:", error.response?.data || error);
      res.status(500).json({
        error: "Internal Server Error",
        details: error.response?.data || error.message,
      });
    }
  });
});
