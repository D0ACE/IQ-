import * as admin from "firebase-admin";
admin.initializeApp(); // MUST be first

import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import cors from "cors";
import * as AWS from "aws-sdk";

import { runNcrReminderJob } from "./jobs/ncrReminderJob";

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
const costExplorer = new AWS.CostExplorer({ region: "us-east-1" });

const corsHandler = cors({ origin: true });

/* =======================
   AWS DASHBOARD API
======================= */
export const getAwsDashboardData = onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      /* IAM */
      const iamUsers = await iam.listUsers().promise();

      /* EC2 */
      const ec2Data = await ec2
        .describeInstances({
          Filters: [
            { Name: "instance-state-name", Values: ["running"] },
          ],
        })
        .promise();

      const ec2Count =
        ec2Data.Reservations?.reduce(
          (sum: number, r: AWS.EC2.Reservation) =>
            sum + (r.Instances?.length || 0),
          0
        ) || 0;

      /* S3 */
      const s3Buckets = await s3.listBuckets().promise();

      /* CloudFront */
      const cfData = await cloudFront.listDistributions().promise();

      /* Billing */
      const today = new Date();
      const start = new Date(today.getFullYear(), today.getMonth(), 1)
        .toISOString()
        .split("T")[0];
      const end = today.toISOString().split("T")[0];

      const billing = await costExplorer
        .getCostAndUsage({
          TimePeriod: { Start: start, End: end },
          Granularity: "MONTHLY",
          Metrics: ["UnblendedCost"],
          GroupBy: [{ Type: "DIMENSION", Key: "SERVICE" }],
        })
        .promise();

      res.json({
        iamUsers: iamUsers.Users?.length || 0,
        ec2RunningInstances: ec2Count,
        s3Buckets: s3Buckets.Buckets?.length || 0,
        cloudFrontDistributions:
          cfData.DistributionList?.Items?.length || 0,
        billing:
          billing.ResultsByTime?.[0].Groups?.map(g => ({
            service: g.Keys?.[0],
            cost: g.Metrics?.UnblendedCost?.Amount,
          })) || [],
      });
    } catch (e: any) {
      console.error(e);
      res.status(500).json({ error: e.message });
    }
  });
});

/* =======================
   LIST ALL AWS RESOURCES
======================= */
export const listAllAwsResources = onRequest(async (req, res) => {
  try {
    /* ===================== S3 ===================== */
    const s3BucketsRes = await s3.listBuckets().promise();

    const s3Buckets = await Promise.all(
      (s3BucketsRes.Buckets || []).map(async (bucket) => {
        const location = await s3
          .getBucketLocation({ Bucket: bucket.Name! })
          .promise();

        const versioning = await s3
          .getBucketVersioning({ Bucket: bucket.Name! })
          .promise();

        return {
          name: bucket.Name,
          createdAt: bucket.CreationDate,
          region: location.LocationConstraint || "us-east-1",
          versioning: versioning.Status || "Disabled",
        };
      })
    );

    /* ===================== EC2 (N. Virginia) ===================== */
    const ec2Data = await ec2.describeInstances().promise();

console.log(
  "EC2 RAW RESPONSE:",
  JSON.stringify(ec2Data.Reservations, null, 2)
);

const sts = new AWS.STS();

const identity = await sts.getCallerIdentity().promise();
console.log("AWS IDENTITY:", identity);

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

          tags: i.Tags?.reduce((acc: any, t) => {
            acc[t.Key!] = t.Value;
            return acc;
          }, {}),
        }))
      ) || [];

    /* ===================== IAM ===================== */
    const iamUsersRes = await iam.listUsers().promise();

    const iamUsers = await Promise.all(
      (iamUsersRes.Users || []).map(async (user) => {
        const policies = await iam
          .listAttachedUserPolicies({ UserName: user.UserName! })
          .promise();

        return {
          userName: user.UserName,
          arn: user.Arn,
          createdAt: user.CreateDate,
          passwordLastUsed: user.PasswordLastUsed,
          attachedPolicies: policies.AttachedPolicies?.map(
            (p) => p.PolicyName
          ),
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

    /* ===================== Billing ===================== */
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), 1)
      .toISOString()
      .split("T")[0];
    const end = today.toISOString().split("T")[0];

    const billingRes = await costExplorer
      .getCostAndUsage({
        TimePeriod: { Start: start, End: end },
        Granularity: "MONTHLY",
        Metrics: ["UnblendedCost"],
        GroupBy: [{ Type: "DIMENSION", Key: "SERVICE" }],
      })
      .promise();

    const billing =
      billingRes.ResultsByTime?.[0].Groups?.map((g) => ({
        service: g.Keys?.[0],
        amount: Number(g.Metrics?.UnblendedCost?.Amount || 0),
        unit: g.Metrics?.UnblendedCost?.Unit,
      })) || [];

    /* ===================== RESPONSE ===================== */
    res.json({
      region: "us-east-1",
      summary: {
        s3Buckets: s3Buckets.length,
        ec2Instances: ec2Instances.length,
        iamUsers: iamUsers.length,
        cloudFrontDistributions: cloudFrontDistributions.length,
      },
      details: {
        s3: s3Buckets,
        ec2: ec2Instances,
        iam: iamUsers,
        cloudFront: cloudFrontDistributions,
        billing,
      },
    });
  } catch (error: any) {
    console.error("AWS RESOURCE ERROR:", error);
    res.status(500).json({
      error: error.message || "Failed to fetch AWS resources",
    });
  }
});
