import * as admin from "firebase-admin";
admin.initializeApp(); // MUST be first

import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import cors from "cors";
import * as AWS from "aws-sdk";

import {runNcrReminderJob} from "./jobs/ncrReminderJob";

/* =======================
   NCR Scheduled Job
======================= */
export const ncrDailyReminder = onSchedule(
  {
    schedule: "every day 01:00",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    await runNcrReminderJob();
  }
);

/* =======================
   AWS CONFIG (v2 SAFE)
======================= */
AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  region: process.env.AWS_REGION!,
});

const iam = new AWS.IAM();
const ec2 = new AWS.EC2({
  region: "us-east-1", // N. Virginia
});
const s3 = new AWS.S3();
const cloudFront = new AWS.CloudFront();
const costExplorer = new AWS.CostExplorer({region: "us-east-1"});

const corsHandler = cors({origin: true});

/* =======================
   LIST ALL AWS RESOURCES
======================= */
export const listAllAwsResources = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    try {
      // ✅ Handle browser preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      /* ===================== S3 ===================== */
      const s3BucketsRes = await s3.listBuckets().promise();

      const s3Buckets = await Promise.all(
        (s3BucketsRes.Buckets || []).map(async (bucket) => {
          const location = await s3
            .getBucketLocation({Bucket: bucket.Name!})
            .promise();

          const versioning = await s3
            .getBucketVersioning({Bucket: bucket.Name!})
            .promise();

          return {
            name: bucket.Name,
            createdAt: bucket.CreationDate,
            region: location.LocationConstraint || "us-east-1",
            versioning: versioning.Status || "Disabled",
          };
        })
      );

      /* ===================== EC2 ===================== */
      const ec2Data = await ec2.describeInstances().promise();

      const ec2Instances =
        ec2Data.Reservations?.flatMap((r) =>
          (r.Instances || []).map((i) => ({
            instanceId: i.InstanceId,
            name:
              i.Tags?.find((t) => t.Key === "Name")?.Value || "N/A",
            state: i.State?.Name,
            instanceType: i.InstanceType,
            amiId: i.ImageId,
            launchTime: i.LaunchTime,
            publicIp: i.PublicIpAddress,
            privateIp: i.PrivateIpAddress,
            availabilityZone: i.Placement?.AvailabilityZone,
            vpcId: i.VpcId,
            subnetId: i.SubnetId,
            keyName: i.KeyName,
            securityGroups: i.SecurityGroups?.map((sg) => ({
              id: sg.GroupId,
              name: sg.GroupName,
            })),
            tags: i.Tags?.reduce<Record<string, string>>(
              (acc, t) => {
                if (t.Key && t.Value) acc[t.Key] = t.Value;
                return acc;
              },
              {}
            ),
          }))
        ) || [];

      /* ===================== IAM ===================== */
      const iamUsersRes = await iam.listUsers().promise();

      const iamUsers = await Promise.all(
        (iamUsersRes.Users || []).map(async (user) => {
          const policies = await iam
            .listAttachedUserPolicies({UserName: user.UserName!})
            .promise();

          return {
            userName: user.UserName,
            arn: user.Arn,
            createdAt: user.CreateDate,
            passwordLastUsed: user.PasswordLastUsed,
            attachedPolicies:
              policies.AttachedPolicies?.map((p) => p.PolicyName) ||
              [],
          };
        })
      );

      /* ===================== CloudFront ===================== */
      const cfRes = await cloudFront.listDistributions().promise();

      const cloudFrontDistributions =
        cfRes.DistributionList?.Items?.map((d) => ({
          id: d.Id,
          domain: d.DomainName,
          enabled: d.Enabled,
          priceClass: d.PriceClass,
          lastModified: d.LastModifiedTime,
          aliases: d.Aliases?.Items || [],
          origins: d.Origins?.Items?.map((o) => ({
            id: o.Id,
            domain: o.DomainName,
          })),
        })) || [];

      /* ===================== RESPONSE ===================== */
      res.status(200).json({
        region: "us-east-1",
        summary: {
          s3Buckets: s3Buckets.length,
          ec2Instances: ec2Instances.length,
          iamUsers: iamUsers.length,
          cloudFrontDistributions:
            cloudFrontDistributions.length,
        },
        details: {
          s3: s3Buckets,
          ec2: ec2Instances,
          iam: iamUsers,
          cloudFront: cloudFrontDistributions,
        },
      });
    } catch (error: unknown) {
      console.error("AWS RESOURCE ERROR:", error);
      res.status(500).json({
        error: "Failed to fetch AWS resources",
      });
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
      const today = new Date();

      const start = new Date(
        today.getFullYear(),
        today.getMonth(),
        1
      )
        .toISOString()
        .split("T")[0];

      const end = today.toISOString().split("T")[0];

      /* =======================
         AWS BILLING
      ======================= */
      const billingRes = await costExplorer
        .getCostAndUsage({
          TimePeriod: {
            Start: start, End: end,
          },
          Granularity: "MONTHLY",
          Metrics: ["UnblendedCost"],
          GroupBy: [
            {
              Type: "DIMENSION",
              Key: "SERVICE",
            },
          ],
        })
        .promise();

      const billing =
        billingRes.ResultsByTime?.[0].Groups?.map((g) => ({
          service: g.Keys?.[0],
          amount: Number(
            g.Metrics?.UnblendedCost?.Amount || 0
          ),
          unit: g.Metrics?.UnblendedCost?.Unit,
        })) || [];

      // =====================
      // Clear Old Billing Docs
      // =====================
      const billingCollection = admin.firestore().
        collection("aws_billing_daily");
        // Check if collection has any docs
      const snapshot = await billingCollection.limit(1).get();

      if (!snapshot.empty) {
        const snapshot = await billingCollection.get();

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
      }

      // =====================
      // Add Fresh Billing Data
      // =====================
      await billingCollection.add({
        billing,
        region: "us-east-1",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        "✅ AWS billing stored",
      );
    } catch (error) {
      console.error(
        "❌ AWS Billing Scheduler Error:",
        error
      );
    }
  }
);
