import * as admin from "firebase-admin";
admin.initializeApp();

import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import cors from "cors";

/* =============================================================================
   LAZY INITIALIZATION HELPERS
   Prevents deployment timeouts by delaying heavy imports/configs until needed.
============================================================================= */

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
    const docsSnapshot = await db.collection("documents").get();

    for (const doc of docsSnapshot.docs) {
      const data = doc.data();
      const createdAt = data.created_at?.toDate();
      if (!createdAt) continue;

      const isAnniversary =
        now.getMonth() === createdAt.getMonth() &&
        now.getDate() === createdAt.getDate() &&
        now.getFullYear() > createdAt.getFullYear();

      if (isAnniversary) {
        const historyRef = doc.ref.collection("version_history");
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

        await historyRef.add({
          docId: doc.id,
          versionNo: nextVersion,
          changeDescription: "Annual Compliance Review - No changes required",
          performedBy: "System (Auto-Review)",
          performedDate: admin.firestore.FieldValue.serverTimestamp(),
          status: "active",
          assignedReviewerName: data.assigned_reviewer_name || "System",
        });

        await doc.ref.update({
          current_version: nextVersion,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (data.assigned_reviewer_id) {
          const userDoc = await db.collection("users")
            .doc(data.assigned_reviewer_id)
            .get();
          const userData = userDoc.data();
          if (userData && userData.email) {
            await BrevoEmailService.sendReviewRequest(
              userData.email,
              userData.userName || "Consultant",
              data.title || "Untitled Document"
            );
          }
        }
      }
    }
  }
);

/* =======================
   LIST ALL AWS RESOURCES
======================= */
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

/* =======================
   DAILY BILLING SCHEDULER
======================= */
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

/* =============================================================================
   DOCUMENT VERSIONING TRIGGER
============================================================================= */
export const onDocumentUpdatedVersioning = onDocumentUpdated(
  "documents/{docId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const contentChanged = before.content !== after.content;
    const titleChanged = before.title !== after.title;
    const reviewerChanged =
      before.assigned_reviewer_id !== after.assigned_reviewer_id;

    if (!contentChanged && !titleChanged && !reviewerChanged) return;

    const historyRef = admin.firestore()
      .collection("documents")
      .doc(event.params.docId)
      .collection("version_history");

    const historySnapshot = await historyRef
      .orderBy("performedDate", "desc")
      .limit(1)
      .get();

    let lastVersion = "V1";
    if (!historySnapshot.empty) {
      lastVersion = historySnapshot.docs[0].data().versionNo || "V1";
    }

    let nextVersion: string;
    if (contentChanged) {
      const majorNum = parseInt(lastVersion.substring(1).split(".")[0]);
      nextVersion = `V${majorNum + 1}`;
    } else {
      const parts = lastVersion.substring(1).split(".");
      const major = parts[0];
      const minor = parts.length > 1 ? parseInt(parts[1]) : 0;
      nextVersion = `V${major}.${minor + 1}`;
    }

    if (after.current_version === nextVersion) return;

    const description = after.last_change_description ||
      (contentChanged ? "Content updated" : "Metadata updated");

    await historyRef.add({
      docId: event.params.docId,
      versionNo: nextVersion,
      changeDescription: description,
      performedBy: after.last_updated_by || "System",
      performedDate: admin.firestore.FieldValue.serverTimestamp(),
      status: "draft",
      assignedReviewerName: after.assigned_reviewer_name || null,
    });

    await event.data?.after.ref.update({
      current_version: nextVersion,
      status: "draft",
      version: "V1",
    });

    console.log(`✅ Version ${nextVersion} for ${event.params.docId}`);
  }
);
