import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import '../models/supplier.dart';
import '../providers/rating_provider.dart';
import '../providers/supplier_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/supplier_detail_modal.dart';

class ApprovedSuppliersScreen extends StatefulWidget {
  const ApprovedSuppliersScreen({super.key});

  @override
  State<ApprovedSuppliersScreen> createState() =>
      _ApprovedSuppliersScreenState();
}

class _ApprovedSuppliersScreenState extends State<ApprovedSuppliersScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _sortColumn = 'id';
  bool _sortAscending = true;

  final List<String> _statusOptions = [
    'Approved',
    'Pending',
    'Temporary',
    'Not Recommended',
    'Non-existing',
    'All',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<Supplier> _filterAndSort(List<Supplier> list) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = list.where((s) {
      // Status filter
      if (_selectedStatus != 'All' && s.status != _selectedStatus) {
        return false;
      }
      // Search filter
      if (query.isNotEmpty) {
        final matchId = s.id.toLowerCase().contains(query);
        final matchName = s.name.toLowerCase().contains(query);
        final matchItem = s.productRange.toLowerCase().contains(query);
        final matchAddress = s.address.toLowerCase().contains(query);
        if (!matchId && !matchName && !matchItem && !matchAddress) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'id':
          cmp = a.id.compareTo(b.id);
          break;
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'item':
          cmp = a.productRange.toLowerCase().compareTo(
            b.productRange.toLowerCase(),
          );
          break;
        case 'date':
          cmp = a.dateOfInclusion.compareTo(b.dateOfInclusion);
          break;
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        case 'purchaseMethod':
          cmp = a.purchaseMethod.compareTo(b.purchaseMethod);
          break;
        default:
          cmp = a.id.compareTo(b.id);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _confirmDelete(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier Record?'),
        content: Text(
          'Are you sure you want to delete ${supplier.name} (${supplier.id})? This will permanently remove the supplier from the registry and cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.notRecommendedRed,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final supplierId = supplier.id;
              final supplierName = supplier.name;
              final provider = context.read<SupplierProvider>();
              final ratingRepo = context.read<RatingProvider>().repository;
              Navigator.of(ctx).pop();
              await provider.deleteSupplier(supplierId);
              await ratingRepo.deleteRatingsForSupplier(supplierId);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Supplier "$supplierName" ($supplierId) deleted successfully.',
                  ),
                  backgroundColor: AppTheme.notRecommendedRed,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _changeStatusDialog(BuildContext context, Supplier supplier) {
    String selected = supplier.status;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Change Status: ${supplier.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Status: ${supplier.status}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'New Status'),
                items: const [
                  DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'Temporary',
                    child: Text('Temporary'),
                  ),
                  DropdownMenuItem(
                    value: 'Not Recommended',
                    child: Text('Not Recommended'),
                  ),
                  DropdownMenuItem(
                    value: 'Non-existing',
                    child: Text('Non-existing'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selected = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.notRecommendedRed,
              ),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete Supplier'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, supplier);
              },
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final provider = context.read<SupplierProvider>();
                Navigator.of(ctx).pop();
                await provider.updateStatus(supplier.id, selected);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Updated status for ${supplier.name} to $selected.',
                    ),
                  ),
                );
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _editSupplierDialog(BuildContext context, Supplier supplier) {
    final nameCtrl = TextEditingController(text: supplier.name);
    final addrCtrl = TextEditingController(text: supplier.address);
    final phoneCtrl = TextEditingController(text: supplier.phone);
    final productCtrl = TextEditingController(text: supplier.productRange);
    final gstCtrl = TextEditingController(text: supplier.gstNo ?? '');
    String purchaseMethod = supplier.purchaseMethod;
    String status = supplier.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setEditState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(children: [Text('Edit Supplier: ${supplier.id}')]),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name*',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(labelText: 'Address*'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Telephone*'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: productCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Items Supplied / Service*',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gstCtrl,
                    decoration: const InputDecoration(labelText: 'GST Reg No.'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: purchaseMethod,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Method',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'With PO',
                              child: Text('With PO'),
                            ),
                            DropdownMenuItem(
                              value: 'Verbal',
                              child: Text('Verbal'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setEditState(() => purchaseMethod = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Approved',
                              child: Text('Approved'),
                            ),
                            DropdownMenuItem(
                              value: 'Temporary',
                              child: Text('Temporary'),
                            ),
                            DropdownMenuItem(
                              value: 'Not Recommended',
                              child: Text('Not Recommended'),
                            ),
                            DropdownMenuItem(
                              value: 'Non-existing',
                              child: Text('Non-existing'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setEditState(() => status = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.notRecommendedRed,
              ),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete Supplier'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, supplier);
              },
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                final provider = context.read<SupplierProvider>();

                if (nameCtrl.text.trim().isEmpty ||
                    addrCtrl.text.trim().isEmpty ||
                    phoneCtrl.text.trim().isEmpty ||
                    productCtrl.text.trim().isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields.'),
                    ),
                  );
                  return;
                }

                final updated = supplier.copyWith(
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  productRange: productCtrl.text.trim(),
                  gstNo: gstCtrl.text.trim().toUpperCase(),
                  purchaseMethod: purchaseMethod,
                  status: status,
                );

                try {
                  await provider.updateSupplier(updated);
                  nav.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Supplier ${supplier.id} updated successfully.',
                      ),
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.notRecommendedRed,
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final roleId = getIt<HiveService>().getUser()?.roleId;
    final canManage =
        roleId == AppConst.adminRole || roleId == AppConst.consultantRole;
    final allSuppliers = supplierProvider.suppliers;
    final displayedList = _filterAndSort(allSuppliers);
    final recentlyAddedId = supplierProvider.recentlyAddedId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Approved Supplier\'s List',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.approvedGreen.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${supplierProvider.approvedCount} Active Approved',
                              style: const TextStyle(
                                color: AppTheme.approvedGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'F-7.4-01/R01 · Master register of approved vendors and procurement sources',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),

                  // Actions: Export & Register
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                        ),
                        label: const Text('Export CSV'),
                        onPressed: displayedList.isEmpty
                            ? null
                            : () => ExportService.exportApprovedSuppliersToCsv(
                                displayedList,
                              ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                        ),
                        label: const Text('Export PDF (F-7.4-01)'),
                        onPressed: displayedList.isEmpty
                            ? null
                            : () => ExportService.exportApprovedSuppliersToPdf(
                                displayedList,
                              ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Register Supplier'),
                        onPressed: () =>
                            context.go(AppRoutes.supplyRegistration),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter & Search Controls Bar
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Search input
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText:
                                'Search by ID (MSP/..), Supplier Name, or Items Supplied...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Status Filter
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            items: _statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Result count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Showing ${displayedList.length} of ${allSuppliers.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Table or Empty State
              if (displayedList.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStatus == 'Approved'
                              ? 'No approved suppliers yet. Register one.'
                              : 'No suppliers match the current filter or search criteria.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Suppliers marked "Recommended = Yes" during registration appear here automatically.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Register New Supplier'),
                          onPressed: () =>
                              context.go(AppRoutes.supplyRegistration),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1200),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        horizontalMargin: 16,
                        columnSpacing: 18,
                        dataRowMinHeight: 65,
                        dataRowMaxHeight: 75,
                        columns: [
                          const DataColumn(
                            label: Text(
                              'Sl No',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            onSort: (index, _) => _onSort('id'),
                            label: Row(
                              children: [
                                const Text(
                                  'ID No',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                _sortIndicator('id'),
                              ],
                            ),
                          ),
                          DataColumn(
                            onSort: (index, _) => _onSort('name'),
                            label: Row(
                              children: [
                                const Text(
                                  'Supplier Name & Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                _sortIndicator('name'),
                              ],
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Contact Person',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Phone / Fax',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            onSort: (index, _) => _onSort('item'),
                            label: Row(
                              children: [
                                const Text(
                                  'Items Supplied / Service',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                _sortIndicator('item'),
                              ],
                            ),
                          ),
                          DataColumn(
                            onSort: (index, _) => _onSort('purchaseMethod'),
                            label: Row(
                              children: [
                                const Text(
                                  'Method of Purchase',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                _sortIndicator('purchaseMethod'),
                              ],
                            ),
                          ),
                          DataColumn(
                            onSort: (index, _) => _onSort('date'),
                            label: Row(
                              children: [
                                const Text(
                                  'Date of Inclusion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                _sortIndicator('date'),
                              ],
                            ),
                          ),
                          DataColumn(
                            onSort: (index, _) => _onSort('status'),
                            label: Row(
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                _sortIndicator('status'),
                              ],
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                        rows: displayedList.asMap().entries.map((entry) {
                          final slNo = entry.key + 1;
                          final s = entry.value;
                          final isRecentlyAdded = s.id == recentlyAddedId;

                          final contactStr = s.contacts.isNotEmpty
                              ? s.contacts.first.name
                              : '-';
                          final desigStr = s.contacts.isNotEmpty
                              ? s.contacts.first.designation
                              : '';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (isRecentlyAdded) {
                                return const Color(
                                  0xFFFEF9C3,
                                ); // Soft yellow highlight
                              }
                              return null;
                            }),
                            cells: [
                              DataCell(
                                Text(
                                  '$slNo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    s.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      contactStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (desigStr.isNotEmpty)
                                      Text(
                                        desigStr,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.phone,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (s.fax != null && s.fax!.isNotEmpty)
                                      Text(
                                        'Fax: ${s.fax}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    s.productRange,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  s.purchaseMethod,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  s.dateOfInclusion,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                StatusBadge(status: s.status, compact: true),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      tooltip:
                                          'View Full Registration (R/PUR-03)',
                                      onPressed: () => SupplierDetailModal.show(
                                        context,
                                        s,
                                        onDelete: canManage
                                            ? () {
                                                Navigator.of(context).pop();
                                                _confirmDelete(context, s);
                                              }
                                            : null,
                                      ),
                                    ),
                                    if (canManage) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        tooltip: 'Edit Supplier',
                                        onPressed: () =>
                                            _editSupplierDialog(context, s),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.swap_horiz_rounded,
                                          size: 18,
                                        ),
                                        tooltip: 'Change Status',
                                        onPressed: () =>
                                            _changeStatusDialog(context, s),
                                      ),
                                    ],
                                    const SizedBox(width: 6),
                                    if (canManage)
                                      InkWell(
                                        onTap: () => _confirmDelete(context, s),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.notRecommendedRed
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 15,
                                                color:
                                                    AppTheme.notRecommendedRed,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme
                                                      .notRecommendedRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortIndicator(String col) {
    if (_sortColumn != col) return const SizedBox();
    return Icon(
      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: AppTheme.primaryLight,
    );
  }
}
