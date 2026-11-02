import 'dart:convert';
import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class _AuditColors {
  static const navy = AppColors.brandPrimary;
  static const green = AppColors.semanticSuccessDark;
  static const gold = AppColors.semanticWarning;
  static const pageBackground = AppColors.neutralBackground;
  static const headerBackground = AppColors.neutralSurfaceMuted;
  static const border = AppColors.neutralBorder;
  static const mutedText = AppColors.neutralTextSecondary;
}

class StandardRequirement {
  /// Creates a checklist requirement from its identifying details.
  const StandardRequirement({
    required this.id,
    required this.clause,
    required this.description,
  });

  /// Creates a requirement from a checklist JSON object.
  factory StandardRequirement.fromJson(Map<String, dynamic> json) {
    return StandardRequirement(
      id: json['id'] as String? ?? '',
      clause: json['clause'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clause': clause,
    'description': description,
  };

  final String id;
  final String clause;
  final String description;
}

class AuditAttachment {
  /// Creates an attachment record with its display name, extension, url, and optional base64 data.
  AuditAttachment({
    required this.name,
    required this.extension,
    this.url = '',
    this.base64Data = '',
  });

  final String name;
  final String extension;
  String url;
  String base64Data;

  bool get isImage {
    final ext = extension.toLowerCase().replaceAll('.', '').trim();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'}.contains(ext);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'extension': extension,
    'url': url,
    'base64Data': base64Data,
  };

  factory AuditAttachment.fromJson(Map<String, dynamic> json) {
    return AuditAttachment(
      name: json['name'] as String? ?? '',
      extension: json['extension'] as String? ?? '',
      url: json['url'] as String? ?? '',
      base64Data: json['base64Data'] as String? ?? '',
    );
  }
}

class AuditRowModel {
  /// Creates an editable audit row for a standard requirement.
  AuditRowModel(this.requirement)
    : createdAt = DateTime.now(),
      comments = TextEditingController(),
      auditor = TextEditingController();

  final StandardRequirement requirement;
  DateTime createdAt;
  final TextEditingController comments;
  final TextEditingController auditor;
  final List<AuditAttachment> attachments = [];
  String? auditeeEmployeeId;
  String? status;
  DateTime? savedAt;
  bool emailSent = false;

  Map<String, dynamic> toJson() => {
    'requirement': requirement.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'comments': comments.text,
    'auditor': auditor.text,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'auditeeEmployeeId': auditeeEmployeeId,
    'status': status,
    'savedAt': savedAt?.toIso8601String(),
    'emailSent': emailSent,
  };

  factory AuditRowModel.fromJson(
    Map<String, dynamic> json,
    StandardRequirement requirement,
  ) {
    final row = AuditRowModel(requirement);
    if (json['createdAt'] != null) {
      row.createdAt =
          DateTime.tryParse(json['createdAt'] as String) ?? row.createdAt;
    }
    row.comments.text = json['comments'] as String? ?? '';
    row.auditor.text = json['auditor'] as String? ?? '';
    if (json['attachments'] is List) {
      for (final a in (json['attachments'] as List)) {
        if (a is Map) {
          row.attachments.add(
            AuditAttachment.fromJson(Map<String, dynamic>.from(a)),
          );
        }
      }
    }
    row.auditeeEmployeeId = json['auditeeEmployeeId'] as String?;
    row.status = json['status'] as String?;
    if (json['savedAt'] != null) {
      row.savedAt = DateTime.tryParse(json['savedAt'] as String);
    }
    row.emailSent = json['emailSent'] as bool? ?? false;
    return row;
  }

  /// Releases the text controllers owned by this row.
  void dispose() {
    comments.dispose();
    auditor.dispose();
  }
}

class AuditWorksheetModel {
  /// Creates a worksheet and initializes one row for each requirement.
  AuditWorksheetModel({
    required this.id,
    required List<StandardRequirement> requirements,
    this.customerId = '',
    this.customerName = '',
    DateTime? createdAt,
    List<AuditRowModel>? rows,
  }) : createdAt = createdAt ?? DateTime.now(),
       rows = rows ?? requirements.map(AuditRowModel.new).toList();

  final int id;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final List<AuditRowModel> rows;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'createdAt': createdAt.toIso8601String(),
    'rows': rows.map((r) => r.toJson()).toList(),
  };

  factory AuditWorksheetModel.fromJson(
    Map<String, dynamic> json,
    List<StandardRequirement> standardRequirements,
  ) {
    final id = json['id'] as int? ?? 1;
    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now();

    final reqMap = {for (final r in standardRequirements) r.id: r};
    final rowList = <AuditRowModel>[];

    if (json['rows'] is List) {
      for (final rJson in (json['rows'] as List)) {
        if (rJson is Map) {
          final map = Map<String, dynamic>.from(rJson);
          String reqId = '';
          if (map['requirement'] is Map) {
            reqId = (map['requirement'] as Map)['id'] as String? ?? '';
          }
          final req =
              reqMap[reqId] ??
              (map['requirement'] is Map
                  ? StandardRequirement.fromJson(
                      Map<String, dynamic>.from(map['requirement'] as Map),
                    )
                  : StandardRequirement(
                      id: reqId,
                      clause: map['clause'] as String? ?? '',
                      description: map['description'] as String? ?? '',
                    ));
          rowList.add(AuditRowModel.fromJson(map, req));
        }
      }
    }

    if (rowList.isEmpty) {
      rowList.addAll(standardRequirements.map(AuditRowModel.new));
    }

    return AuditWorksheetModel(
      id: id,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      requirements: standardRequirements,
      createdAt: createdAt,
      rows: rowList,
    );
  }

  /// Releases the resources owned by every row in the worksheet.
  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
  }
}

class AuditReportPage extends StatefulWidget {
  /// Creates the page that lists submitted audit worksheets.
  const AuditReportPage({this.isReadOnly, super.key});

  final bool? isReadOnly;

  @override
  /// Creates the mutable state for the checklist page.
  State<AuditReportPage> createState() => _AuditReportPageState();
}

class _AuditReportPageState extends State<AuditReportPage> {
  List<StandardRequirement> _requirements = [];
  List<EmployeeUserModel> _employees = [];
  final List<AuditWorksheetModel> _submittedWorksheets = [];
  CustomerModel? _selectedCustomer;
  bool _loading = true;

  bool get _isReadOnly {
    if (widget.isReadOnly != null) return widget.isReadOnly!;
    final user = getIt<HiveService>().getUser();
    final roleId = user?.roleId;
    return Utility.isAdmin(roleId) || Utility.isSuperAdmin(roleId);
  }

  String? get _customerIdForVisibility {
    final customer = getIt<HiveService>().getCustomer();
    if (customer != null && Utility.isCustomer(customer.roleId)) {
      return customer.customerId;
    }
    return null;
  }

  List<AuditWorksheetModel> _visibleWorksheets(
    Iterable<AuditWorksheetModel> worksheets,
  ) {
    final customerId = _customerIdForVisibility;
    if (customerId == null || customerId.isEmpty) {
      return worksheets.toList();
    }
    return worksheets
        .where((worksheet) => worksheet.customerId == customerId)
        .toList();
  }

  @override
  /// Loads checklist requirements, employees, and saved worksheets when initialized.
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadChecklist();
    await _loadEmployees();
    await _loadSavedWorksheets();
  }

  Future<void> _loadEmployees() async {
    final user = getIt<HiveService>().getUser();
    final customer = getIt<HiveService>().getCustomer();
    List<String>? customerIds;
    String? consultantId;

    if (user != null && Utility.isConsultant(user.roleId)) {
      consultantId = user.userId;
    } else if (customer != null && Utility.isCustomer(customer.roleId)) {
      customerIds = [customer.customerId];
    } else if (user != null &&
        Utility.isEmployee(user.roleId) &&
        user.customerId != null &&
        user.customerId!.isNotEmpty) {
      customerIds = [user.customerId!];
    }

    try {
      final employees = await getIt<UserRepository>().fetchEmployees(
        customerIds: customerIds,
        createdBy: consultantId,
      );
      if (!mounted) return;
      setState(() {
        _employees = employees
            .where((employee) => !employee.blockStatus)
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching employees: $e');
    }
  }

  /// Reads and parses the checklist requirements from bundled JSON.
  Future<void> _loadChecklist() async {
    try {
      final source = await rootBundle.loadString('assets/checklist.json');
      final json = jsonDecode(source) as Map<String, dynamic>;
      final requirements = (json['requirements'] as List<dynamic>)
          .map(
            (entry) =>
                StandardRequirement.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _requirements = requirements;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _requirements = const [
          StandardRequirement(
            id: 'starter-1',
            clause: 'Audit requirement',
            description: 'Add checklist requirements to assets/checklist.json.',
          ),
        ];
        _loading = false;
      });
      _message(
        'Checklist asset not found; using the starter requirement.',
        error: true,
      );
    }
  }

  /// Loads worksheets saved previously in Hive box and Cloud Firestore.
  Future<void> _loadSavedWorksheets() async {
    // 1. Instant load from local Hive
    try {
      final box = await Hive.openBox('audit_worksheets_box');
      final raw = box.get('worksheets');
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final list = decoded.map((item) {
          return AuditWorksheetModel.fromJson(
            Map<String, dynamic>.from(item as Map),
            _requirements,
          );
        }).toList();
        final visibleList = _visibleWorksheets(list);
        if (mounted && visibleList.isNotEmpty) {
          setState(() {
            _submittedWorksheets.clear();
            _submittedWorksheets.addAll(visibleList);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved worksheets from Hive: $e');
    }

    // 2. Sync from Firestore so all Superadmins, Admins, and Consultants see the same data
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('audit_worksheets')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final cloudList = <AuditWorksheetModel>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            cloudList.add(AuditWorksheetModel.fromJson(data, _requirements));
          } catch (err) {
            debugPrint('Error parsing worksheet ${doc.id}: $err');
          }
        }

        final visibleCloudList = _visibleWorksheets(cloudList)
          ..sort((a, b) => b.id.compareTo(a.id));

        if (mounted) {
          setState(() {
            _submittedWorksheets.clear();
            _submittedWorksheets.addAll(visibleCloudList);
          });
          // Update local Hive cache with cloud data
          final box = await Hive.openBox('audit_worksheets_box');
          final encoded = jsonEncode(
            _submittedWorksheets.map((w) => w.toJson()).toList(),
          );
          await box.put('worksheets', encoded);
        }
      }
    } catch (e) {
      debugPrint('Error syncing worksheets from Firestore: $e');
    }
  }

  /// Persists worksheets to local Hive box and Cloud Firestore.
  Future<void> _persistWorksheets() async {
    // Save to Hive
    try {
      final box = await Hive.openBox('audit_worksheets_box');
      final encoded = jsonEncode(
        _submittedWorksheets.map((w) => w.toJson()).toList(),
      );
      await box.put('worksheets', encoded);
    } catch (e) {
      debugPrint('Error persisting audit worksheets to Hive: $e');
    }

    // Sync to Cloud Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      for (final worksheet in _submittedWorksheets) {
        await firestore
            .collection('audit_worksheets')
            .doc('worksheet_${worksheet.id}')
            .set(worksheet.toJson(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error persisting audit worksheets to Firestore: $e');
    }
  }

  /// Creates a new worksheet with the lowest currently unused identifier.
  AuditWorksheetModel _newWorksheet() {
    final customerName = _selectedCustomer?.companyName.trim() ?? '';
    final usedIds = _submittedWorksheets
        .map((worksheet) => worksheet.id)
        .toSet();
    var nextId = 1;
    while (usedIds.contains(nextId)) {
      nextId++;
    }
    return AuditWorksheetModel(
      id: nextId,
      customerId: _selectedCustomer?.customerId ?? '',
      customerName: customerName,
      requirements: _requirements,
    );
  }

  /// Opens a blank worksheet and stores it after creation/editing.
  Future<void> _addWorksheet() async {
    if (_isReadOnly || _selectedCustomer == null) return;
    final draft = _newWorksheet();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AuditFormPage(
          worksheet: draft,
          employees: _employees,
          readOnly: false,
          onWorksheetUpdated: () {
            if (!_submittedWorksheets.any((w) => w.id == draft.id)) {
              _submittedWorksheets.insert(0, draft);
            }
            _persistWorksheets();
            if (mounted) setState(() {});
          },
        ),
      ),
    );

    final hasSavedOrEnteredData = draft.rows.any(
      (r) =>
          r.savedAt != null ||
          r.status != null ||
          r.comments.text.trim().isNotEmpty ||
          r.attachments.isNotEmpty,
    );

    if (hasSavedOrEnteredData) {
      if (!_submittedWorksheets.any((w) => w.id == draft.id)) {
        _submittedWorksheets.insert(0, draft);
      }
      await _persistWorksheets();
      if (mounted) setState(() {});
    } else {
      if (!_submittedWorksheets.any((w) => w.id == draft.id)) {
        draft.dispose();
      }
    }
  }

  /// Opens an existing Audit Report for viewing (or continuing editing if consultant).
  Future<void> _openWorksheet(AuditWorksheetModel worksheet) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AuditFormPage(
          worksheet: worksheet,
          employees: _employees,
          readOnly: _isReadOnly,
          onWorksheetUpdated: () {
            if (!_isReadOnly) {
              _persistWorksheets();
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
    if (!_isReadOnly) {
      await _persistWorksheets();
      if (mounted) setState(() {});
    }
  }

  /// Confirms and removes a submitted worksheet from the list.
  Future<void> _deleteWorksheet(AuditWorksheetModel worksheet) async {
    if (_isReadOnly) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Audit Report ${worksheet.id}?'),
        content: const Text(
          'This Audit Report and all of its local entries will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonDarkGreen,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submittedWorksheets.remove(worksheet));
    worksheet.dispose();
    await _persistWorksheets();
    try {
      await FirebaseFirestore.instance
          .collection('audit_worksheets')
          .doc('worksheet_${worksheet.id}')
          .delete();
    } catch (e) {
      debugPrint('Error deleting audit worksheet from Firestore: $e');
    }
    _message('Audit Report ${worksheet.id} deleted.');
  }

  /// Shows a success or error message in a floating snackbar.
  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? AppColors.semanticErrorDark
              : AppColors.semanticSuccessDark,
        ),
      );
  }

  @override
  /// Releases all submitted worksheets when the page is disposed.
  void dispose() {
    for (final worksheet in _submittedWorksheets) {
      worksheet.dispose();
    }
    super.dispose();
  }

  @override
  /// Builds the worksheet list and controls for the home page.
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _AuditColors.pageBackground,
        cardTheme: const CardThemeData(
          color: AppColors.cardBg,
          surfaceTintColor: Colors.white,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: _AuditColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: _AuditColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: _AuditColors.green, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.buttonDarkGreen,
            foregroundColor: AppColors.buttonYellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.buttonDarkGreen,
            side: const BorderSide(color: _AuditColors.green),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _AuditColors.navy,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _AuditColors.navy),
          shape: const Border(bottom: BorderSide(color: _AuditColors.border)),
          title: const Text(
            'Internal Audit Report',
            style: TextStyle(
              color: _AuditColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            if (_isReadOnly)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: _AuditColors.navy,
                  ),
                  label: Text(
                    'Read Only',
                    style: TextStyle(
                      color: _AuditColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: _AuditColors.headerBackground,
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _HomePage(
                submittedWorksheets: _submittedWorksheets,
                isReadOnly: _isReadOnly,
                selectedCustomer: _selectedCustomer,
                consultantId: getIt<HiveService>().getUser()?.userId,
                onCustomerChanged: (customer) {
                  setState(() => _selectedCustomer = customer);
                },
                onAddForm: _addWorksheet,
                onOpenForm: _openWorksheet,
                onDeleteForm: _deleteWorksheet,
              ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  /// Creates the home page content and worksheet callbacks.
  const _HomePage({
    required this.submittedWorksheets,
    required this.isReadOnly,
    required this.selectedCustomer,
    required this.consultantId,
    required this.onCustomerChanged,
    required this.onAddForm,
    required this.onOpenForm,
    required this.onDeleteForm,
  });

  final List<AuditWorksheetModel> submittedWorksheets;
  final bool isReadOnly;
  final CustomerModel? selectedCustomer;
  final String? consultantId;
  final ValueChanged<CustomerModel?> onCustomerChanged;
  final VoidCallback onAddForm;
  final ValueChanged<AuditWorksheetModel> onOpenForm;
  final ValueChanged<AuditWorksheetModel> onDeleteForm;

  @override
  /// Builds the empty state or the submitted worksheet cards.
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        if (!isReadOnly) ...[
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Customer',
                    style: TextStyle(
                      color: _AuditColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomerDropdownWidget(
                    selectedCustomer: selectedCustomer,
                    consultantId: consultantId,
                    onChanged: onCustomerChanged,
                    hint: 'Select a customer to add an audit report',
                  ),
                  if (selectedCustomer != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: onAddForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Report'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Internal Audit Report',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _AuditColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          submittedWorksheets.isEmpty
              ? (isReadOnly
                    ? 'No audit reports available for review.'
                    : 'No Audit Reports created yet. Click Create Report to begin.')
              : 'Audit Reports & Worksheets',
          style: const TextStyle(color: _AuditColors.mutedText, fontSize: 16),
        ),
        const SizedBox(height: 20),
        if (submittedWorksheets.isEmpty && isReadOnly)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.table_rows_outlined,
                  size: 56,
                  color: AppColors.neutralTextSecondary,
                ),
                SizedBox(height: 14),
                Text(
                  'No audit reports available',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Internal audit reports submitted by consultants will appear here for review.',
                  style: TextStyle(color: _AuditColors.mutedText, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (submittedWorksheets.isNotEmpty)
          ...submittedWorksheets.map(
            (worksheet) => _SubmittedFormCard(
              worksheet: worksheet,
              isReadOnly: isReadOnly,
              onTap: () => onOpenForm(worksheet),
              onDelete: () => onDeleteForm(worksheet),
            ),
          ),
      ],
    );
  }
}

class _SubmittedFormCard extends StatelessWidget {
  /// Creates a card summarizing one submitted worksheet.
  const _SubmittedFormCard({
    required this.worksheet,
    required this.isReadOnly,
    required this.onTap,
    required this.onDelete,
  });

  final AuditWorksheetModel worksheet;
  final bool isReadOnly;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  /// Builds the worksheet summary, status counts, and actions.
  Widget build(BuildContext context) {
    final statuses = <String, int>{};
    int savedCount = 0;
    for (final row in worksheet.rows) {
      if (row.savedAt != null) {
        savedCount++;
      }
      if (row.status != null) {
        statuses[row.status!] = (statuses[row.status!] ?? 0) + 1;
      }
    }
    final isFullyCompleted =
        savedCount > 0 && savedCount == worksheet.rows.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isFullyCompleted
              ? AppColors.semanticSuccess.withValues(alpha: 0.15)
              : _AuditColors.headerBackground,
          child: Icon(
            isFullyCompleted
                ? Icons.check_circle
                : (isReadOnly
                      ? Icons.visibility_outlined
                      : Icons.edit_note_rounded),
            color: isFullyCompleted ? _AuditColors.green : _AuditColors.navy,
          ),
        ),
        title: Text(
          'Audit Report ${worksheet.id} (${worksheet.customerName.isEmpty ? "Customer" : worksheet.customerName})  •  ${isFullyCompleted ? "Completed" : "$savedCount of ${worksheet.rows.length} Saved"}',
          style: const TextStyle(
            color: _AuditColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Created: ${_formatDate(worksheet.createdAt)}\n'
            '${statuses.isEmpty ? 'No row saved yet' : statuses.entries.map((entry) => '${entry.key}: ${entry.value}').join('  |  ')}',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                (isReadOnly || isFullyCompleted)
                    ? Icons.visibility_outlined
                    : Icons.edit_outlined,
                size: 16,
              ),
              label: Text(
                (isReadOnly || isFullyCompleted) ? 'View' : 'Continue Edit',
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
            ),
            if (!isReadOnly) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Delete Audit Report',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.semanticError,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formats a timestamp for display in a submitted worksheet card.
  String _formatDate(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    return '${value.day}/${value.month}/${value.year} '
        '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class AuditFormPage extends StatefulWidget {
  /// Creates a page for editing or viewing one worksheet.
  const AuditFormPage({
    required this.worksheet,
    required this.employees,
    this.readOnly = false,
    this.onWorksheetUpdated,
    super.key,
  });

  final AuditWorksheetModel worksheet;
  final List<EmployeeUserModel> employees;
  final bool readOnly;
  final VoidCallback? onWorksheetUpdated;

  @override
  State<AuditFormPage> createState() => _AuditFormPageState();
}

class _AuditFormPageState extends State<AuditFormPage> {
  @override
  Widget build(BuildContext context) {
    final savedCount = widget.worksheet.rows
        .where((r) => r.savedAt != null)
        .length;
    final totalRows = widget.worksheet.rows.length;
    final allSaved = savedCount > 0 && savedCount == totalRows;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!widget.readOnly) {
          widget.onWorksheetUpdated?.call();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _AuditColors.navy,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _AuditColors.navy),
          shape: const Border(bottom: BorderSide(color: _AuditColors.border)),
          title: Text(
            widget.readOnly
                ? 'Audit Report ${widget.worksheet.id} (${widget.worksheet.customerName.isEmpty ? "Customer" : widget.worksheet.customerName}) • Read Only'
                : 'Audit Report ${widget.worksheet.id} (${widget.worksheet.customerName.isEmpty ? "Customer" : widget.worksheet.customerName})',
            style: const TextStyle(
              color: _AuditColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: widget.readOnly
                  ? const Chip(
                      avatar: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: _AuditColors.navy,
                      ),
                      label: Text(
                        'Read Only',
                        style: TextStyle(
                          color: _AuditColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: _AuditColors.headerBackground,
                    )
                  : allSaved
                  ? const Chip(
                      avatar: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _AuditColors.green,
                      ),
                      label: Text('Completed'),
                    )
                  : FilledButton.icon(
                      onPressed: () {
                        widget.onWorksheetUpdated?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('SUBMIT'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.buttonDarkGreen,
                        foregroundColor: AppColors.buttonYellow,
                      ),
                    ),
            ),
          ],
        ),
        body: AuditWorksheet(
          worksheet: widget.worksheet,
          employees: widget.employees,
          readOnly: widget.readOnly,
          onChanged: () {
            if (!widget.readOnly) {
              widget.onWorksheetUpdated?.call();
              if (mounted) setState(() {});
            }
          },
          onError: (message) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.semanticErrorDark,
            ),
          ),
          onSave: widget.readOnly
              ? null
              : () {
                  widget.onWorksheetUpdated?.call();
                  Navigator.of(context).pop();
                },
        ),
      ),
    );
  }
}

class AuditWorksheet extends StatelessWidget {
  /// Creates the worksheet table and its interaction callbacks.
  const AuditWorksheet({
    required this.worksheet,
    required this.employees,
    required this.onChanged,
    required this.onError,
    required this.onSave,
    this.readOnly = false,
    super.key,
  });

  final AuditWorksheetModel worksheet;
  final List<EmployeeUserModel> employees;
  final VoidCallback onChanged;
  final ValueChanged<String> onError;
  final VoidCallback? onSave;
  final bool readOnly;

  @override
  /// Builds the responsive worksheet header and requirement rows.
  Widget build(BuildContext context) {
    return SizedBox(
      height: 700,
      child: Card(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const baseWidths = [
              55.0,
              270.0,
              330.0,
              220.0,
              260.0,
              145.0,
              190.0,
              190.0,
              150.0,
            ];
            final baseTotal = baseWidths.reduce((a, b) => a + b);
            final widths = constraints.maxWidth >= baseTotal
                ? baseWidths
                : constraints.maxWidth >= 900
                ? baseWidths
                      .map((width) => width * constraints.maxWidth / baseTotal)
                      .toList()
                : baseWidths;
            return Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          readOnly
                              ? 'Viewing audit report in read-only mode.'
                              : 'Save individual rows to dispatch result emails. Unsaved rows can be edited anytime.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _AuditColors.mutedText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (!readOnly && onSave != null)
                          FilledButton.icon(
                            onPressed: onSave,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('SAVE & CLOSE'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: widths.reduce((a, b) => a + b),
                          child: Column(
                            children: [
                              _WorksheetHeader(widths: widths),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: worksheet.rows.length,
                                  itemBuilder: (context, index) {
                                    final requirement =
                                        worksheet.rows[index].requirement;
                                    final hasClause = requirement.clause
                                        .trim()
                                        .isNotEmpty;
                                    var rowSpan = 1;
                                    if (hasClause) {
                                      while (index + rowSpan <
                                              worksheet.rows.length &&
                                          worksheet
                                              .rows[index + rowSpan]
                                              .requirement
                                              .clause
                                              .trim()
                                              .isEmpty) {
                                        rowSpan++;
                                      }
                                    }
                                    return AuditWorksheetRow(
                                      index: index,
                                      row: worksheet.rows[index],
                                      widths: widths,
                                      readOnly: readOnly,
                                      onChanged: onChanged,
                                      onError: onError,
                                      employees: employees,
                                      requirementRowSpan: hasClause
                                          ? rowSpan
                                          : 0,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorksheetHeader extends StatelessWidget {
  /// Creates the table header using the supplied column widths.
  const _WorksheetHeader({required this.widths});

  final List<double> widths;

  @override
  /// Builds the row of worksheet column headers.
  Widget build(BuildContext context) {
    const labels = [
      '#',
      'Standard Requirements',
      'Description of the Requirement',
      'Upload',
      'Comments / Objective Evidence',
      'Result',
      'Auditee',
      'Auditor',
      'Save',
    ];
    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(
          labels.length,
          (index) => _HeaderCell(label: labels[index], width: widths[index]),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  /// Creates one styled worksheet header cell.
  const _HeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  /// Builds the header cell with its label and border.
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _AuditColors.border, width: 0.5),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: _AuditColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AuditWorksheetRow extends StatefulWidget {
  /// Creates a row for one requirement and its audit inputs.
  const AuditWorksheetRow({
    required this.index,
    required this.row,
    required this.widths,
    required this.readOnly,
    required this.onChanged,
    required this.onError,
    required this.employees,
    required this.requirementRowSpan,
    super.key,
  });

  final int index;
  final AuditRowModel row;
  final List<double> widths;
  final bool readOnly;
  final VoidCallback onChanged;
  final ValueChanged<String> onError;
  final List<EmployeeUserModel> employees;
  final int requirementRowSpan;

  @override
  State<AuditWorksheetRow> createState() => _AuditWorksheetRowState();
}

class _AuditWorksheetRowState extends State<AuditWorksheetRow> {
  bool _isSaving = false;

  /// Saves the individual row, sends its audit result email, and records the save timestamp.
  Future<void> _saveRow() async {
    if (widget.readOnly) return;

    final auditeeId = widget.row.auditeeEmployeeId?.trim();
    if (auditeeId == null || auditeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an Auditee before saving so the result email can be sent.',
          ),
          backgroundColor: AppColors.semanticWarning,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final auditee = widget.employees.cast<EmployeeUserModel?>().firstWhere(
      (emp) => emp?.userId.trim() == auditeeId,
      orElse: () => null,
    );

    if (auditee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected auditee was not found in active employee list.',
          ),
          backgroundColor: AppColors.semanticWarning,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final auditeeEmail = auditee.email.trim();
    if (auditeeEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auditee ${auditee.userName} has no email address configured.',
          ),
          backgroundColor: AppColors.semanticWarning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = widget.row.status ?? 'Not Specified';
      final sent = await BrevoEmailService.sendAuditResultMail(
        auditeeEmail: auditeeEmail,
        auditeeName: auditee.userName,
        clause: widget.row.requirement.clause,
        requirement: widget.row.requirement.description,
        result: result,
        comments: widget.row.comments.text.trim(),
        auditor: widget.row.auditor.text.trim(),
      );

      widget.row.savedAt = DateTime.now();
      widget.row.emailSent = sent;
      widget.onChanged();

      if (mounted) {
        if (sent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Row saved! Audit report emailed to ${auditee.userName} ($auditeeEmail)',
              ),
              backgroundColor: AppColors.semanticSuccessDark,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Row saved, but email could not be delivered to $auditeeEmail. Please verify configuration.',
              ),
              backgroundColor: AppColors.semanticWarning,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      widget.row.savedAt = DateTime.now();
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Row saved with notification: $e'),
            backgroundColor: AppColors.semanticWarning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Formats the row save time for display below the Save button.
  String _formatSavedAt(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}\n'
        '$hour:$minute:$second ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  /// Builds the requirement details, attachment control, and input fields.
  Widget build(BuildContext context) {
    final isLocked = widget.readOnly || widget.row.savedAt != null;
    final background = widget.index.isEven
        ? AppColors.neutralSurface
        : AppColors.neutralSurfaceMuted;
    return SizedBox(
      height: 96,
      child: Container(
        color: widget.requirementRowSpan == 0 ? Colors.transparent : background,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BodyCell(
              width: widget.widths[0],
              child: Text('${widget.index + 1}'),
            ),
            if (widget.requirementRowSpan == 0)
              SizedBox(width: widget.widths[1])
            else
              _BodyCell(
                width: widget.widths[1],
                height: 96.0 * widget.requirementRowSpan,
                child: Text(
                  widget.row.requirement.clause,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            _BodyCell(
              width: widget.widths[2],
              child: Text(
                widget.row.requirement.description.isEmpty
                    ? '—'
                    : widget.row.requirement.description,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _BodyCell(
              width: widget.widths[3],
              child: AttachmentCell(
                row: widget.row,
                readOnly: isLocked,
                onChanged: widget.onChanged,
                onError: widget.onError,
              ),
            ),
            _BodyCell(
              width: widget.widths[4],
              child: IgnorePointer(
                ignoring: isLocked,
                child: TextField(
                  controller: widget.row.comments,
                  readOnly: isLocked,
                  minLines: 2,
                  maxLines: 5,
                  onChanged: (_) => widget.onChanged(),
                  decoration: InputDecoration(
                    hintText: isLocked ? '—' : 'Enter evidence...',
                  ),
                ),
              ),
            ),
            _BodyCell(
              width: widget.widths[5],
              child: IgnorePointer(
                ignoring: isLocked,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.row.status,
                  onTap: isLocked ? () {} : null,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'Select'),
                  items: const ['Complied', 'OI', 'Minor-NC', 'Major-NC', 'NA']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: isLocked
                      ? null
                      : (value) {
                          widget.row.status = value;
                          widget.onChanged();
                        },
                ),
              ),
            ),
            _BodyCell(
              width: widget.widths[6],
              child: IgnorePointer(
                ignoring: isLocked,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      widget.employees.any(
                        (employee) =>
                            employee.userId == widget.row.auditeeEmployeeId,
                      )
                      ? widget.row.auditeeEmployeeId
                      : null,
                  onTap: isLocked ? () {} : null,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'Select auditee'),
                  items: widget.employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee.userId,
                          child: Text(
                            employee.userName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isLocked
                      ? null
                      : (value) {
                          widget.row.auditeeEmployeeId = value;
                          widget.onChanged();
                        },
                ),
              ),
            ),
            _BodyCell(
              width: widget.widths[7],
              child: IgnorePointer(
                ignoring: isLocked,
                child: TextField(
                  controller: widget.row.auditor,
                  readOnly: isLocked,
                  onChanged: (_) => widget.onChanged(),
                  decoration: InputDecoration(
                    hintText: isLocked ? '—' : 'Auditor',
                  ),
                ),
              ),
            ),
            _BodyCell(
              width: widget.widths[8],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.row.savedAt == null)
                    (widget.readOnly
                        ? const Text(
                            'Unsaved',
                            style: TextStyle(
                              fontSize: 12,
                              color: _AuditColors.mutedText,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : OutlinedButton(
                            onPressed: isLocked || _isSaving ? null : _saveRow,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('SAVE'),
                          ))
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: _AuditColors.green,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'SAVED',
                          style: TextStyle(
                            color: _AuditColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  if (widget.row.savedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatSavedAt(widget.row.savedAt!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: _AuditColors.mutedText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  /// Creates a bordered worksheet body cell.
  const _BodyCell({required this.width, required this.child, this.height});

  final double width;
  final Widget child;
  final double? height;

  @override
  /// Builds a body cell with consistent sizing and padding.
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: _AuditColors.border, width: 0.5),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class AttachmentCell extends StatefulWidget {
  /// Creates the attachment picker and viewer for one audit row.
  const AttachmentCell({
    required this.row,
    required this.readOnly,
    required this.onChanged,
    required this.onError,
    super.key,
  });

  final AuditRowModel row;
  final bool readOnly;
  final VoidCallback onChanged;
  final ValueChanged<String> onError;

  @override
  State<AttachmentCell> createState() => _AttachmentCellState();
}

class _AttachmentCellState extends State<AttachmentCell> {
  static const allowed = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'txt',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
  };
  bool _loading = false;

  /// Opens the file picker, uploads files to Supabase Storage, and adds them to the audit row.
  Future<void> _pickFiles() async {
    if (widget.readOnly) return;
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowed.toList(),
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final supabase = Supabase.instance.client;

      for (final file in result.files) {
        final extension = (file.extension ?? '').toLowerCase();
        if (!allowed.contains(extension)) {
          widget.onError('Unsupported file format: ${file.name}');
          continue;
        }

        final fileName = file.name;
        final bytes = file.bytes;
        String fileUrl = '';
        String base64Data = '';

        if (bytes != null) {
          try {
            final sanitizedFileName = fileName.replaceAll(
              RegExp(r'[^\w\.\-]'),
              '_',
            );
            final String supabasePath =
                'audit_attachments/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

            await supabase.storage
                .from(SupabaseConfig.bucketName)
                .uploadBinary(
                  supabasePath,
                  bytes,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: true,
                  ),
                );

            fileUrl = supabase.storage
                .from(SupabaseConfig.bucketName)
                .getPublicUrl(supabasePath);
          } catch (uploadError) {
            debugPrint('Supabase upload fallback: $uploadError');
            base64Data = base64Encode(bytes);
          }
        }

        widget.row.attachments.add(
          AuditAttachment(
            name: fileName,
            extension: extension,
            url: fileUrl,
            base64Data: base64Data,
          ),
        );
      }
      widget.onChanged();
    } on Object catch (error) {
      widget.onError('Unable to select attachment: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Downloads an attachment on Web, Mobile, or Desktop.
  Future<void> _downloadAttachment(AuditAttachment attachment) async {
    try {
      final fileName = attachment.name.isNotEmpty
          ? attachment.name
          : 'attachment_${DateTime.now().millisecondsSinceEpoch}.${attachment.extension}';

      if (kIsWeb) {
        if (attachment.url.isNotEmpty) {
          final anchor = html.AnchorElement(href: attachment.url)
            ..setAttribute('download', fileName)
            ..target = '_blank';
          html.document.body?.children.add(anchor);
          anchor.click();
          anchor.remove();
        } else if (attachment.base64Data.isNotEmpty) {
          final rawBase64 = attachment.base64Data.contains(',')
              ? attachment.base64Data.split(',').last
              : attachment.base64Data;
          final bytes = base64Decode(rawBase64);
          final blob = html.Blob([bytes]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: blobUrl)
            ..setAttribute('download', fileName);
          html.document.body?.children.add(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(blobUrl);
        } else {
          throw 'File content is not available for download.';
        }
      } else {
        if (attachment.url.isNotEmpty) {
          final uri = Uri.tryParse(attachment.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch URL: ${attachment.url}';
          }
        } else if (attachment.base64Data.isNotEmpty) {
          final rawBase64 = attachment.base64Data.contains(',')
              ? attachment.base64Data.split(',').last
              : attachment.base64Data;
          final bytes = base64Decode(rawBase64);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          final uri = Uri.file(file.path);
          await launchUrl(uri);
        } else {
          throw 'File content is not available for download.';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${attachment.name}...'),
            backgroundColor: AppColors.semanticSuccessDark,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: AppColors.semanticErrorDark,
          ),
        );
      }
    }
  }

  /// Displays the full image preview in a responsive popup dialog.
  void _showImagePopup(AuditAttachment attachment) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 680),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          attachment.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Download Image',
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _downloadAttachment(attachment),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),

                // Image Viewer Body
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E1E1E),
                    alignment: Alignment.center,
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _buildImageViewer(attachment),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Format: .${attachment.extension.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.buttonDarkGreen,
                              foregroundColor: AppColors.buttonYellow,
                            ),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('DOWNLOAD'),
                            onPressed: () => _downloadAttachment(attachment),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandPrimary,
                              side: const BorderSide(
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('CLOSE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageViewer(AuditAttachment attachment) {
    if (attachment.url.isNotEmpty) {
      return Image.network(
        attachment.url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          final loaded = loadingProgress.cumulativeBytesLoaded;
          return Center(
            child: CircularProgressIndicator(
              value: total != null ? loaded / total : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (attachment.base64Data.isNotEmpty) {
            return _buildBase64Image(attachment.base64Data);
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.white70,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image preview: $error',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } else if (attachment.base64Data.isNotEmpty) {
      return _buildBase64Image(attachment.base64Data);
    } else {
      return const Center(
        child: Text(
          'Image preview not available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
  }

  Widget _buildBase64Image(String rawBase64) {
    try {
      final clean = rawBase64.contains(',')
          ? rawBase64.split(',').last
          : rawBase64;
      final bytes = base64Decode(clean);
      return Image.memory(bytes, fit: BoxFit.contain);
    } catch (e) {
      return Center(
        child: Text(
          'Invalid image data: $e',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase().replaceAll('.', '')) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileIconColor(String ext) {
    switch (ext.toLowerCase().replaceAll('.', '')) {
      case 'pdf':
        return Colors.red.shade700;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Colors.green.shade700;
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  /// Builds the add-attachment button and selected file list with preview popup and download.
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickFiles,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file, size: 17),
                label: Text(_loading ? 'Uploading...' : 'Add'),
              ),
            )
          else if (widget.row.attachments.isEmpty)
            const Text(
              'No attachments',
              style: TextStyle(
                fontSize: 12,
                color: _AuditColors.mutedText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ...widget.row.attachments.asMap().entries.map((entry) {
            final attachment = entry.value;
            return Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _AuditColors.border, width: 0.8),
              ),
              child: Row(
                children: [
                  // Thumbnail or Icon
                  if (attachment.isImage)
                    InkWell(
                      onTap: () => _showImagePopup(attachment),
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: attachment.url.isNotEmpty
                            ? Image.network(
                                attachment.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image,
                                  size: 16,
                                  color: AppColors.brandPrimary,
                                ),
                              )
                            : (attachment.base64Data.isNotEmpty
                                  ? _buildBase64Image(attachment.base64Data)
                                  : const Icon(
                                      Icons.image,
                                      size: 16,
                                      color: AppColors.brandPrimary,
                                    )),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        _getFileIcon(attachment.extension),
                        size: 20,
                        color: _getFileIconColor(attachment.extension),
                      ),
                    ),

                  // File Name (Clickable)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (attachment.isImage) {
                          _showImagePopup(attachment);
                        } else {
                          _downloadAttachment(attachment);
                        }
                      },
                      child: Tooltip(
                        message: attachment.isImage
                            ? 'Click to preview in popup: ${attachment.name}'
                            : 'Click to download: ${attachment.name}',
                        child: Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: attachment.isImage
                                ? AppColors.brandPrimary
                                : Colors.black87,
                            decoration: attachment.isImage
                                ? TextDecoration.underline
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // View Popup Button (for Images)
                  if (attachment.isImage)
                    IconButton(
                      tooltip: 'View in popup',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.brandPrimary,
                      ),
                      onPressed: () => _showImagePopup(attachment),
                    ),

                  // Download Button (for all files and images)
                  IconButton(
                    tooltip: 'Download file',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: AppColors.semanticSuccessDark,
                    ),
                    onPressed: () => _downloadAttachment(attachment),
                  ),

                  // Remove Attachment (only when editable)
                  if (!widget.readOnly)
                    IconButton(
                      tooltip: 'Remove attachment',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 15,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        widget.row.attachments.removeAt(entry.key);
                        widget.onChanged();
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
