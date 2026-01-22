import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/ncr_form/ncr_form_page.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'package:provider/provider.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';

class NcrPage extends StatefulWidget {
  const NcrPage({super.key});

  @override
  State<NcrPage> createState() => _NcrPageState();
}

class _NcrPageState extends State<NcrPage> {
  @override
  void initState() {
    super.initState();
    context.read<NcrProvider>().listenToNcrs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteTextColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add new form',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            GoRouter.of(
              context,
            ).push(AppRoutes.NCRFormPage); // navigate using GoRouter
          },
        ),
      ),
      appBar: AppBar(
        title: const Text('NCR List'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<NcrProvider>(
          builder: (context, provider, _) {
            if (provider.ncrList.isEmpty) {
              return const Center(child: Text("No NCRs found"));
            }

            return ListView.builder(
              itemCount: provider.ncrList.length,
              itemBuilder: (context, index) {
                final ncr = provider.ncrList[index];
                return NcrListCard(
                  ncr: ncr,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NCRFormPage(ncrData: ncr),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NcrListCard extends StatelessWidget {
  final Map<String, dynamic> ncr;
  final VoidCallback onTap;

  const NcrListCard({super.key, required this.ncr, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ncr['status'] ?? 'open';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        title: Text(
          ncr['process'] ?? 'N/A',
          style: AppThemeData.textFieldTextStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.blackTextColor,
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _statusText(status),
            style: TextStyle(
              color: _statusColor(status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
