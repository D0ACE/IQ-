import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/pages/add_user_dialog.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'blocked'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters => _searchQuery.isNotEmpty || _statusFilter != 'all';

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = 'all';
    });
  }

  List<dynamic> _getFilteredUsers(List<dynamic> users) {
    return users.where((user) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final userName = (user.userName ?? '').toString().toLowerCase();
        final email = (user.email ?? '').toString().toLowerCase();
        final phone = (user.phoneNumber ?? '').toString().toLowerCase();
        final designation = (user is EmployeeUserModel && user.designation != null)
            ? user.designation!.toLowerCase()
            : '';

        final matches = userName.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            designation.contains(q);

        if (!matches) return false;
      }

      // 2. Active / Blocked Status Filter
      final bool isBlocked = (user.blockStatus ?? false) == true;
      if (_statusFilter == 'active' && isBlocked) {
        return false;
      }
      if (_statusFilter == 'blocked' && !isBlocked) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.titleText,
        centerTitle: false,
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final userCubit = context.read<UserCubit>();
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: userCubit,
              child: const AddUserDialog(),
            ),
          );
        },
        backgroundColor: AppColors.kPrimaryColor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text("Add User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 🎨 Background Pattern
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  dotColor: AppColors.kPrimaryColor.withValues(alpha: 0.03),
                ),
              ),
            ),
          ),

          BlocConsumer<UserCubit, UserState>(
            listener: (context, state) {
              if (state is UserError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<UserCubit>();
              if (state is UserLoading && cubit.users.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final allUsers = cubit.users;

              if (allUsers.isEmpty && state is UserLoaded) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No users found",
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              final filteredUsers = _getFilteredUsers(allUsers);
              final int totalCount = allUsers.length;
              final int activeCount = allUsers.where((u) => u.blockStatus != true).length;
              final int blockedCount = allUsers.where((u) => u.blockStatus == true).length;

              return Column(
                children: [
                  if (state is UserLoading)
                    const LinearProgressIndicator(minHeight: 2),

                  // 🔍 Search Bar & Filter Header Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        // Search Field
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name, email, phone...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.kPrimaryColor,
                                size: 22,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 🟢 Active / Blocked Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildStatusChip(
                                label: 'All ($totalCount)',
                                value: 'all',
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                label: 'Active ($activeCount)',
                                value: 'active',
                                activeColor: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                label: 'Blocked ($blockedCount)',
                                value: 'blocked',
                                activeColor: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📊 Active Filter Indicator Bar
                  if (_hasActiveFilters)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Showing ${filteredUsers.length} of ${allUsers.length} users",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.titleText,
                            ),
                          ),
                          GestureDetector(
                            onTap: _clearAllFilters,
                            child: const Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: AppColors.kPrimaryColor),
                                SizedBox(width: 4),
                                Text(
                                  "Clear filters",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 📋 Users List / Empty Filtered State
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No matching users found",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Try adjusting your search query or status filter",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                                  label: const Text("Reset Filters"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _neoModernUserCard(context, cubit, user),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    Color? activeColor,
  }) {
    final bool isSelected = _statusFilter == value;
    final Color color = activeColor ?? AppColors.kPrimaryColor;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = value;
          });
        }
      },
      selectedColor: color,
      backgroundColor: const Color(0xFFF1F5F9),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _neoModernUserCard(BuildContext context, UserCubit userCubit, dynamic user) {
    final String roleId = user.roleId ?? '';
    String roleName = "Consultant";
    Color roleColor = AppColors.kPrimaryColor;

    if (roleId == '0') {
      roleName = 'Super Admin';
      roleColor = Colors.redAccent;
    } else if (roleId == '1') {
      roleName = 'Admin';
      roleColor = Colors.indigo;
    } else if (roleId == '2') {
      roleName = 'Consultant';
      roleColor = AppColors.kPrimaryColor;
    }

    final bool isBlocked = (user.blockStatus ?? false) == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: userCubit,
                  child: AddUserDialog(user: user),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar with Badge
                  Stack(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.kPrimaryColor.withValues(alpha: 0.1),
                              AppColors.kPrimaryColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (user.userName ?? 'U').toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.kPrimaryColor,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            height: 12,
                            width: 12,
                            decoration: BoxDecoration(
                              color: isBlocked ? Colors.red : Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.userName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: AppColors.titleText,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                roleName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: roleColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.alternate_email_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Text(
                              user.phoneNumber ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),
                  // Actions
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: userCubit,
                              child: AddUserDialog(user: user),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_note_rounded, color: AppColors.kPrimaryColor, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => _showDeleteDialog(context, user),
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Delete User",
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
        ),
        content: Text(
          "Are you sure you want to remove ${user.userName} from the system?\nThis action cannot be undone.",
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Keep User",
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserCubit>().deleteUser(user.userId);
            },
            child: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  _DotPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 30.0;
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final List<Offset> points = [];
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
