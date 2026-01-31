import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/aws_dashboard_cubit.dart';
import '../cubit/aws_dashboard_state.dart';
import '../models/aws_resources_model.dart';

class AwsDashboardPage extends StatelessWidget {
  const AwsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AwsDashboardCubit()..loadAwsResources(),
      child: Scaffold(
        appBar: AppBar(title: const Text("AWS Dashboard")),
        body: BlocBuilder<AwsDashboardCubit, AwsDashboardState>(
          builder: (context, state) {
            if (state is AwsDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AwsDashboardError) {
              return Center(child: Text(state.message));
            } else if (state is AwsDashboardLoaded) {
              final data = state.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _regionHeader(data.region),
                    const SizedBox(height: 16),
                    _summarySection(data.summary),
                    const SizedBox(height: 16),
                    _sectionList("S3 Buckets", data.details?.s3?.map((e) => _s3Tile(e)).toList() ?? []),
                    _sectionList("EC2 Instances", data.details?.ec2?.map((e) => _ec2Tile(e)).toList() ?? []),
                    _sectionList("IAM Users", data.details?.iam?.map((e) => _iamTile(e)).toList() ?? []),
                    _sectionList("CloudFront Distributions", data.details?.cloudFront?.map((e) => _cloudFrontTile(e)).toList() ?? []),
                    _sectionList("Billing", data.details?.billing?.map((e) => _billingTile(e)).toList() ?? []),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _regionHeader(String? region) {
    return Text(
      "Region: ${region ?? 'Unknown'}",
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _summarySection(Summary? summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _summaryCard("S3 Buckets", summary?.s3Buckets ?? 0),
        _summaryCard("EC2 Instances", summary?.ec2Instances ?? 0),
        _summaryCard("IAM Users", summary?.iamUsers ?? 0),
        _summaryCard("CloudFront", summary?.cloudFrontDistributions ?? 0),
      ],
    );
  }

  Widget _summaryCard(String title, int value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value.toString(), style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }

  Widget _sectionList(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox();
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: children,
    );
  }

  Widget _s3Tile(S3 s3) {
    return ListTile(
      title: Text(s3.name ?? ""),
      subtitle: Text("Created: ${s3.createdAt}\nRegion: ${s3.region}\nVersioning: ${s3.versioning}"),
    );
  }

  Widget _ec2Tile(Ec2 ec2) {
    return ListTile(
      title: Text(ec2.name ?? ec2.instanceId ?? ""),
      subtitle: Text(
          "State: ${ec2.state}\nType: ${ec2.instanceType}\nPublic IP: ${ec2.publicIp ?? '-'}\nPrivate IP: ${ec2.privateIp ?? '-'}\nAZ: ${ec2.availabilityZone}\nTags: ${ec2.tags?.name ?? '-'}"),
    );
  }

  Widget _iamTile(Iam iam) {
    return ListTile(
      title: Text(iam.userName ?? ""),
      subtitle: Text(
          "ARN: ${iam.arn}\nCreated: ${iam.createdAt}\nPassword Last Used: ${iam.passwordLastUsed ?? '-'}\nPolicies: ${iam.attachedPolicies?.join(', ') ?? '-'}"),
    );
  }

  Widget _cloudFrontTile(CloudFront cf) {
    return ListTile(
      title: Text(cf.domain ?? cf.id ?? ""),
      subtitle: Text(
          "Enabled: ${cf.enabled}\nPrice Class: ${cf.priceClass}\nLast Modified: ${cf.lastModified}\nOrigins: ${cf.origins?.map((e) => e.domain).join(', ') ?? '-'}"),
    );
  }

  Widget _billingTile(Billing bill) {
    return ListTile(
      title: Text(bill.service ?? ""),
      trailing: Text("${bill.amount?.toStringAsFixed(2)} ${bill.unit ?? ''}"),
    );
  }
}
