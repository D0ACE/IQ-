import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';

class AppNavScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppNavScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final approvedCount = supplierProvider.approvedCount;
    final totalCount = supplierProvider.totalCount;

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        leading: !isWide
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : null,
        title: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'SUPPLIER MANAGEMENT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Manufacturing Operations · Purchase Dept',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (isWide) ...[
            _NavButton(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              isSelected: currentPath == '/',
              onTap: () => context.go('/'),
            ),
            _NavButton(
              label: 'Registration (R/PUR-03)',
              icon: Icons.app_registration_outlined,
              isSelected: currentPath == '/register',
              onTap: () => context.go('/register'),
            ),
            _NavButton(
              label: 'Approved Suppliers (F-7.4-01)',
              icon: Icons.verified_outlined,
              badgeText: approvedCount > 0 ? '$approvedCount' : null,
              isSelected: currentPath == '/approved',
              onTap: () => context.go('/approved'),
            ),
            _NavButton(
              label: 'Supply Rating (F-7.4-03)',
              icon: Icons.analytics_outlined,
              isSelected: currentPath == '/rating',
              onTap: () => context.go('/rating'),
            ),
            const SizedBox(width: 16),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderColor, height: 1),
        ),
      ),
      drawer: !isWide
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.precision_manufacturing_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Supplier Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Suppliers: $totalCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Dashboard'),
                    selected: currentPath == '/',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.app_registration_outlined),
                    title: const Text('Supplier Registration (R/PUR-03)'),
                    selected: currentPath == '/register',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/register');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text('Approved Supplier\'s List (F-7.4-01)'),
                    trailing: approvedCount > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryLight,
                            child: Text(
                              '$approvedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : null,
                    selected: currentPath == '/approved',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/approved');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: const Text('Supply Rating (F-7.4-03)'),
                    selected: currentPath == '/rating',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/rating');
                    },
                  ),
                ],
              ),
            )
          : null,
      body: child,
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final String? badgeText;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textDark,
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
