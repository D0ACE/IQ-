import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final approvedCount = supplierProvider.approvedCount;
    final totalCount = supplierProvider.totalCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Welcome to ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Supplier Management',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '',
                      style: TextStyle(fontSize: 15, color: Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Exactly 3 large card buttons as requested
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 950;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _NavigationCard(
                            cardNumber: '01',
                            formCode: 'R/PUR-03',
                            title: 'Supplier Registration',
                            description:
                                'Register new manufacturing partners & dealers. Complete verification checklist, manpower, machinery, and director approvals.',
                            badgeText: 'New Entry',
                            badgeColor: AppTheme.primaryLight,
                            icon: Icons.app_registration_rounded,
                            route: '/register',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _NavigationCard(
                            cardNumber: '02',
                            formCode: 'F-7.4-01 / R01',
                            title: 'Approved Supplier',
                            description:
                                'Approved Supplier\'s List (ASL). Search, filter, view complete records, update statuses, and export to CSV/PDF.',
                            badgeText: '$approvedCount Approved Suppliers',
                            badgeColor: AppTheme.approvedGreen,
                            icon: Icons.verified_user_rounded,
                            route: '/approved',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _NavigationCard(
                            cardNumber: '03',
                            formCode: 'F-7.4-03 / R0',
                            title: 'Supply Rating',
                            description:
                                'Live Quality (QR 70) and Delivery (DR 30) calculations per financial year. Grade badges and performance evaluation.',
                            badgeText: 'Automated Evaluation',
                            badgeColor: AppTheme.secondaryColor,
                            icon: Icons.analytics_rounded,
                            route: '/rating',
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _NavigationCard(
                          cardNumber: '01',
                          formCode: 'R/PUR-03',
                          title: 'Supplier Registration',
                          description:
                              'Register new manufacturing partners & dealers. Complete verification checklist, manpower, machinery, and director approvals.',
                          badgeText: 'New Entry',
                          badgeColor: AppTheme.primaryLight,
                          icon: Icons.app_registration_rounded,
                          route: '/register',
                        ),
                        const SizedBox(height: 16),
                        _NavigationCard(
                          cardNumber: '02',
                          formCode: 'F-7.4-01 / R01',
                          title: 'Approved Supplier',
                          description:
                              'Approved Supplier\'s List (ASL). Search, filter, view complete records, update statuses, and export to CSV/PDF.',
                          badgeText: '$approvedCount Approved Suppliers',
                          badgeColor: AppTheme.approvedGreen,
                          icon: Icons.verified_user_rounded,
                          route: '/approved',
                        ),
                        const SizedBox(height: 16),
                        _NavigationCard(
                          cardNumber: '03',
                          formCode: 'F-7.4-03 / R0',
                          title: 'Supply Rating',
                          description:
                              'Live Quality (QR 70) and Delivery (DR 30) calculations per financial year. Grade badges and performance evaluation.',
                          badgeText: 'Automated Evaluation',
                          badgeColor: AppTheme.secondaryColor,
                          icon: Icons.analytics_rounded,
                          route: '/rating',
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 36),

              // Operational overview stats
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUPPLIER REGISTRY OVERVIEW',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _statTile(
                            'Total Suppliers',
                            '$totalCount',
                            AppTheme.primaryColor,
                          ),
                          _statTile(
                            'Approved (ASL)',
                            '$approvedCount',
                            AppTheme.approvedGreen,
                          ),
                          _statTile(
                            'Temporary',
                            '${supplierProvider.temporaryCount}',
                            AppTheme.temporaryAmber,
                          ),
                          _statTile(
                            'Not Recommended',
                            '${supplierProvider.notRecommendedCount}',
                            AppTheme.notRecommendedRed,
                          ),
                          _statTile(
                            'Non-Existing',
                            '${supplierProvider.nonExistingCount}',
                            AppTheme.nonExistingGrey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String cardNumber;
  final String formCode;
  final String title;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final String route;

  const _NavigationCard({
    required this.cardNumber,
    required this.formCode,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppTheme.primaryLight.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'FORM $formCode',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: badgeColor, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: badgeColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
