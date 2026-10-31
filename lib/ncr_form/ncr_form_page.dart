import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:provider/provider.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';
import 'package:iq_plus/ncr_form/ncr/model/ncr_form_model.dart';
import 'package:iq_plus/ncr_form/ncr/repository/ncr_repository.dart';

class NCRFormPage extends StatefulWidget {
  final Map<String, dynamic>? ncrData;
  final bool forceEdit;

  const NCRFormPage({super.key, this.ncrData, this.forceEdit = false});

  @override
  State<NCRFormPage> createState() => _NCRFormPageState();
}

class _NCRFormPageState extends State<NCRFormPage> {
  File? logo;
  final picker = ImagePicker();
  final NcrRepository _ncrRepository = NcrRepository();
  late bool isReview;
  bool isEditable = true;
  bool isSaving = false;
  String roleId = '';

  // role fetched from Firebase

  /// 🔹 Controllers
  final processCtrl = TextEditingController();
  final iqaCtrl = TextEditingController();
  final clauseCtrl = TextEditingController();
  final ncrNoCtrl = TextEditingController();
  final statementCtrl = TextEditingController();
  final evidenceCtrl = TextEditingController();
  final classificationCtrl = TextEditingController();
  final dueDateCtrl = TextEditingController();

  final correctionCtrl = TextEditingController();
  final plannedDateCtrl = TextEditingController();
  final actualDateCtrl = TextEditingController();
  final rootCauseCtrl = TextEditingController();
  final correctiveCtrl = TextEditingController();

  final verificationCtrl = TextEditingController();
  final auditorCtrl = TextEditingController();
  final approvedCtrl = TextEditingController();

  /// Current status
  String currentStatus = AppConst.openNCRStatusKey;
  bool isRoleLoaded = false;
  bool isStatusUpdating = false;

  CustomerModel? selectedCustomer;
  List<EmployeeUserModel> employeesList = [];
  String? selectedEmployeeId;

  EmployeeUserModel? getSelectedEmployee() {
    try {
      return employeesList.firstWhere((e) => e.userId == selectedEmployeeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadEmployeesForDropdown() async {
    final custId = selectedCustomer?.customerId ?? widget.ncrData?['customerId'] ?? '';

    if (custId.isEmpty) {
      if (mounted) {
        setState(() {
          employeesList = [];
          selectedEmployeeId = null;
        });
      }
      return;
    }

    try {
      List<EmployeeUserModel> emps = [];
      final repo = UserRepository(FirebaseFirestore.instance);

      if (Utility.isSuperAdmin(roleId) || Utility.isAdmin(roleId)) {
        // Admin & SuperAdmin show employees of selected customer
        emps = await repo.fetchEmployees(customerIds: [custId]);
        if (emps.isEmpty) {
          final allEmps = await repo.fetchEmployees();
          emps = allEmps.where((e) => e.customerId == custId).toList();
        }
      } else if (Utility.isConsultant(roleId)) {
        // Consultant: fetch all employees of assigned customers using consultantId and filter by selected customer
        emps = await repo.fetchEmployees(consultantId: userLoginDetails?.userId);
        emps = emps.where((e) => e.customerId == custId).toList();
      } else {
        // Customer or Employee
        emps = await repo.fetchEmployees(customerIds: [custId]);
        if (emps.isEmpty) {
          final allEmps = await repo.fetchEmployees();
          emps = allEmps.where((e) => e.customerId == custId).toList();
        }
      }

      // 🚀 Deduplicate employees by userId to prevent Dropdown duplicate value assertion errors
      final Map<String, EmployeeUserModel> uniqueEmps = {};
      for (final emp in emps) {
        if (emp.userId.isNotEmpty) {
          uniqueEmps[emp.userId] = emp;
        }
      }
      emps = uniqueEmps.values.toList();

      if (!mounted) return;
      setState(() {
        employeesList = emps;

        // If currently selected employee does not belong to the newly loaded employees list, clear selection
        if (selectedEmployeeId != null && !employeesList.any((e) => e.userId == selectedEmployeeId)) {
          selectedEmployeeId = null;
        }

        // Try to match pre-selected employee for edit/view mode if no employee is selected
        if (selectedEmployeeId == null) {
          String targetEmpId = widget.ncrData?['employeeId'] ?? '';
          if (targetEmpId.isEmpty) {
            final empEmail = (widget.ncrData?['employeeEmail'] ?? '').toString().toLowerCase().trim();
            final empName = (widget.ncrData?['employeeName'] ?? '').toString().toLowerCase().trim();
            if (empEmail.isNotEmpty) {
              try {
                targetEmpId = employeesList.firstWhere((e) => e.email.toLowerCase().trim() == empEmail).userId;
              } catch (_) {}
            }
            if (targetEmpId.isEmpty && empName.isNotEmpty) {
              try {
                targetEmpId = employeesList.firstWhere((e) => e.userName.toLowerCase().trim() == empName).userId;
              } catch (_) {}
            }
          }

          if (targetEmpId.isNotEmpty) {
            if (employeesList.any((e) => e.userId == targetEmpId)) {
              selectedEmployeeId = targetEmpId;
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error loading employees for NCR: $e");
    }
  }

  final UserModel? userLoginDetails = getIt<HiveService>().getUser();
  final CustomerModel? customerLoginDetails = getIt<HiveService>()
      .getCustomer();

  @override
  void initState() {
    super.initState();

    /// Determine if this is viewing/reviewing an existing NCR
    isReview = widget.ncrData != null;

    if (isReview) {
      final ncr = widget.ncrData!;
      processCtrl.text = ncr['process'] ?? '';
      iqaCtrl.text = ncr['iqaNo'] ?? '';
      clauseCtrl.text = ncr['clause'] ?? '';
      ncrNoCtrl.text = ncr['ncrNo'] ?? '';
      statementCtrl.text = ncr['statement'] ?? '';
      evidenceCtrl.text = ncr['evidence'] ?? '';
      classificationCtrl.text = ncr['classification'] ?? '';
      dueDateCtrl.text = ncr['dueDate'] ?? '';
      correctionCtrl.text = ncr['correction'] ?? '';
      plannedDateCtrl.text = ncr['plannedDate'] ?? '';
      actualDateCtrl.text = ncr['actualDate'] ?? '';
      rootCauseCtrl.text = ncr['rootCause'] ?? '';
      correctiveCtrl.text = ncr['correctiveAction'] ?? '';
      verificationCtrl.text = ncr['verification'] ?? '';
      auditorCtrl.text = ncr['auditor'] ?? '';
      approvedCtrl.text = ncr['approvedBy'] ?? '';
      currentStatus = ncr['status'] ?? AppConst.openNCRStatusKey;

      fetchCustomer();

      /// Fetch user role from Firebase
      fetchUserRole();
    } else {
      isEditable = true;
      fetchUserRole();
    }
  }

  @override
  void dispose() {
    processCtrl.dispose();
    iqaCtrl.dispose();
    clauseCtrl.dispose();
    ncrNoCtrl.dispose();
    statementCtrl.dispose();
    evidenceCtrl.dispose();
    classificationCtrl.dispose();
    dueDateCtrl.dispose();
    correctionCtrl.dispose();
    plannedDateCtrl.dispose();
    actualDateCtrl.dispose();
    rootCauseCtrl.dispose();
    correctiveCtrl.dispose();
    verificationCtrl.dispose();
    auditorCtrl.dispose();
    approvedCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchCustomer() async {
    final customerId = widget.ncrData?['customerId'] ?? '';
    if (customerId.isEmpty) return;

    try {
      final doc = await getIt<FirebaseFirestore>()
          .collection('customers')
          .doc(customerId)
          .get();

      if (doc.exists && doc.data() != null) {
        if (!mounted) return;
        setState(() {
          selectedCustomer = CustomerModel.fromJson(
            doc.data()!,
            customerId: customerId,
          );
        });
        loadEmployeesForDropdown();
      }
    } catch (e) {
      debugPrint('Error fetching customer: $e');
    }
  }

  void fetchUserRole() {
    roleId = userLoginDetails?.roleId ?? customerLoginDetails?.roleId ?? '';
    isRoleLoaded = true;
    if (isReview) {
      isEditable = widget.forceEdit && !Utility.isCustomer(roleId) && !Utility.isEmployee(roleId);
    }
    loadEmployeesForDropdown();
    setState(() {});
  }

  Future<void> _updateStatus(String newStatus) async {
    final docId = widget.ncrData?['id'];
    if (docId == null || isStatusUpdating) return;

    setState(() {
      isStatusUpdating = true;
    });

    try {
      if (widget.ncrData != null) {
        widget.ncrData!['status'] = newStatus;
      }
      await context.read<NcrProvider>().updateStatus(docId, newStatus);

      if (!mounted) return;
      setState(() {
        currentStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Status updated to ${Utility.getNCRStatus(newStatus)}",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update status: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isStatusUpdating = false;
        });
      }
    }
  }

  /// 🔹 Date Picker
  Future<void> pickDate(TextEditingController controller, {DateTime? firstDate, String? errorMessage}) async {
    if (isReview && !isEditable) return; 

    // Helper to parse dd-MM-yyyy
    DateTime? initial;
    try {
      if (controller.text.isNotEmpty) {
        initial = DateFormat('dd-MM-yyyy').parse(controller.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? (firstDate ?? DateTime.now()),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  void _showPlannedDateFirstError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a Planned Completion Date first."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 🔹 Logo picker
  Future<void> pickLogo() async {
    if (isReview) return; // Prevent changes in review mode
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => logo = File(img.path));
  }

  Widget sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 14, bottom: 8),
      color: AppColors.greyTextFormFiledColor,
      child: Text(
        title,
        style: AppThemeData.textFieldTextStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.blackTextColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          !isReview
              ? "NCR Form"
              : isEditable
                  ? "Edit NCR"
                  : "View NCR",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔹 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyBorderColor),
              ),
              child: const Text(
                "Internal Quality Audit\nNon Conformity Report (NCR)\n(System / Process)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔹 STATUS DISPLAY & COMPACT ACTIONS
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: currentStatus == AppConst.openNCRStatusKey
                    ? AppColors.orange.withValues(alpha: 0.1)
                    : currentStatus == AppConst.inProgressNCRStatusKey
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentStatus == AppConst.openNCRStatusKey
                      ? AppColors.orange.withValues(alpha: 0.3)
                      : currentStatus == AppConst.inProgressNCRStatusKey
                      ? AppColors.blue.withValues(alpha: 0.3)
                      : AppColors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Utility.getNCRStatusIcons(currentStatus),
                        color: currentStatus == AppConst.openNCRStatusKey
                            ? AppColors.orange
                            : currentStatus == AppConst.inProgressNCRStatusKey
                            ? AppColors.blue
                            : AppColors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Status: ${Utility.getNCRStatus(currentStatus)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: currentStatus == AppConst.openNCRStatusKey
                              ? AppColors.orange
                              : currentStatus == AppConst.inProgressNCRStatusKey
                              ? AppColors.blue
                              : AppColors.green,
                        ),
                      ),
                    ],
                  ),

                  /// Status Action Buttons (Super Admin / Admin / Consultant)
                  if (isReview && isRoleLoaded && !Utility.isCustomer(roleId) && !Utility.isEmployee(roleId)) ...[
                    if (currentStatus == AppConst.openNCRStatusKey ||
                        currentStatus == AppConst.inProgressNCRStatusKey) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          // OPEN → IN PROGRESS
                          if (currentStatus == AppConst.openNCRStatusKey)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonDarkGreen,
                                foregroundColor: AppColors.buttonYellow,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                              icon: isStatusUpdating
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(
                                isStatusUpdating ? 'Updating...' : 'Mark In Progress',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: isStatusUpdating
                                  ? null
                                  : () =>
                                      _updateStatus(AppConst.inProgressNCRStatusKey),
                            ),

                          // IN PROGRESS → CLOSE
                          if (currentStatus == AppConst.inProgressNCRStatusKey)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonDarkGreen,
                                foregroundColor: AppColors.buttonYellow,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                              icon: isStatusUpdating
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(
                                isStatusUpdating ? 'Updating...' : 'Close NCR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: isStatusUpdating
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Close NCR"),
                                          content: const Text(
                                            "Are you sure you want to close this NCR?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Yes"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await _updateStatus(AppConst.closedNCRStatusKey);
                                      }
                                    },
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// 🔹 SECTION 5
            sectionHeader("Select Company"),
            CustomerDropdownWidget(
              consultantId: userLoginDetails?.roleId == AppConst.superAdminRole || userLoginDetails?.roleId == AppConst.adminRole
                  ? null
                  : userLoginDetails?.userId,
              selectedCustomer: selectedCustomer,
              readOnly: !isEditable,
              onChanged: (customer) {
                setState(() {
                  selectedCustomer = customer;
                  // If selected employee doesn't belong to the newly selected customer, clear selected employee
                  final currentEmp = getSelectedEmployee();
                  if (currentEmp == null || currentEmp.customerId != customer?.customerId) {
                    selectedEmployeeId = null;
                  }
                  employeesList = [];
                });
                loadEmployeesForDropdown();

                /// 🔥 FULL MODEL AVAILABLE
                debugPrint('Customer ID: ${customer?.customerId}');
                debugPrint('Top Dept Email: ${customer?.topLevelEmail}');
              },
            ),

            const SizedBox(height: 12),
            sectionHeader("Select Employee"),
            GestureDetector(
              onTap: isEditable && (selectedCustomer?.customerId ?? '').isEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a company first"),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  : null,
              child: AbsorbPointer(
                absorbing: isEditable && (selectedCustomer?.customerId ?? '').isEmpty,
                child: DropdownButtonFormField<String>(
                  value: selectedEmployeeId != null && employeesList.any((e) => e.userId == selectedEmployeeId) ? selectedEmployeeId : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: (selectedCustomer?.customerId ?? '').isEmpty ? Colors.grey.shade100 : Colors.white,
                  ),
                  hint: Text(
                    (selectedCustomer?.customerId ?? '').isEmpty
                        ? "Select Company First"
                        : "Select Employee",
                    style: TextStyle(
                      color: (selectedCustomer?.customerId ?? '').isEmpty
                          ? Colors.grey
                          : AppColors.blackTextColor,
                    ),
                  ),
                  items: employeesList.map((emp) {
                    return DropdownMenuItem<String>(
                      value: emp.userId,
                      child: Text("${emp.userName} (${emp.email})"),
                    );
                  }).toList(),
                  onChanged: isEditable && (selectedCustomer?.customerId ?? '').isNotEmpty
                      ? (empId) {
                          setState(() {
                            selectedEmployeeId = empId;
                          });
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 Rest of form sections ...
            sectionHeader("SECTION 1 – DETAILS OF NONCONFORMITY"),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Process / Area / Department",
                    textFieldController: processCtrl,
                    readOnly: !isEditable,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "IQA Number",
                    textFieldController: iqaCtrl,
                    readOnly: !isEditable,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Requirement / Clause No(s)",
                    textFieldController: clauseCtrl,
                    readOnly: !isEditable,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "NCR Number & Date",
                    textFieldController: ncrNoCtrl,
                    readOnly: !isEditable,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Statement of Non Conformity",
              maxLines: 2,
              textFieldController: statementCtrl,
              readOnly: !isEditable,
            ),

            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Objective Evidence",
              textFieldController: evidenceCtrl,
              readOnly: !isEditable,
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Classification",
                    textFieldController: classificationCtrl,
                    readOnly: !isEditable,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Due Date",
                    textFieldController: dueDateCtrl,
                    readOnly: true,
                    onTap: () => isEditable ? pickDate(dueDateCtrl) : null,
                  ),
                ),
              ],
            ),

            /// 🔹 SECTION 2
            sectionHeader("SECTION 2 – AUDITEE PLANNED ACTIONS"),
            AppTextFieldWidget(
              hintText: "Corrections / Containment Action",
              maxLines: 2,
              textFieldController: correctionCtrl,
              readOnly: !isEditable,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Planned Completion Date",
                    textFieldController: plannedDateCtrl,
                    readOnly: true,
                    onTap: () {
                      if (!isEditable) return;
                      pickDate(plannedDateCtrl).then((_) {
                        // Optional: Clear actual date if it's now invalid
                        if (actualDateCtrl.text.isNotEmpty && plannedDateCtrl.text.isNotEmpty) {
                          try {
                            final p = DateFormat('dd-MM-yyyy').parse(plannedDateCtrl.text);
                            final a = DateFormat('dd-MM-yyyy').parse(actualDateCtrl.text);
                            if (a.isBefore(p)) {
                              actualDateCtrl.clear();
                            }
                          } catch (_) {}
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Actual Completion Date",
                    textFieldController: actualDateCtrl,
                    readOnly: true,
                    onTap: () {
                      if (!isEditable) return;
                      
                      DateTime? planned;
                      try {
                        if (plannedDateCtrl.text.isNotEmpty) {
                          planned = DateFormat('dd-MM-yyyy').parse(plannedDateCtrl.text);
                        }
                      } catch (_) {}

                      if (planned == null) {
                        _showPlannedDateFirstError();
                      } else {
                        pickDate(actualDateCtrl, firstDate: planned);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Root Cause",
              maxLines: 2,
              textFieldController: rootCauseCtrl,
              readOnly: !isEditable,
            ),
            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Corrective Actions",
              maxLines: 2,
              textFieldController: correctiveCtrl,
              readOnly: !isEditable,
            ),

            /// 🔹 SECTION 3
            sectionHeader("SECTION 3 – VERIFICATION"),
            AppTextFieldWidget(
              hintText: "Verification Details",
              maxLines: 2,
              textFieldController: verificationCtrl,
              readOnly: !isEditable,
            ),

            /// 🔹 SECTION 4
            sectionHeader("SECTION 4 – NCR CLOSURE"),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Auditor Name / Date",
                    textFieldController: auditorCtrl,
                    readOnly: !isEditable,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Approved by MR",
                    textFieldController: approvedCtrl,
                    readOnly: !isEditable,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// 🔹 SECTION 5
            sectionHeader("SECTION 5 – Auditee Details"),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Name",
                    textFieldController: TextEditingController.fromValue(
                      TextEditingValue(
                        text: selectedCustomer?.lowLevelName ?? "",
                      ),
                    ),
                    readOnly: true,
                    isEnabled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Email",
                    textFieldController: TextEditingController.fromValue(
                      TextEditingValue(
                        text: selectedCustomer?.lowLevelEmail ?? "",
                      ),
                    ),
                    readOnly: true,
                    isEnabled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Phone",
                    textFieldController: TextEditingController.fromValue(
                      TextEditingValue(
                        text: AppValidation.formatPhoneForEdit(selectedCustomer?.lowLevelMobile ?? ""),
                      ),
                    ),
                    readOnly: true,
                    isEnabled: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixText: "+91 ",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// 🔹 SAVE BUTTON / UPDATE BUTTON
            if (!isReview || isEditable)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: GradientButton(
                  text: isReview ? "Update NCR" : "Save NCR",
                  radiusSize: 50,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : () async {
                    if ((selectedCustomer?.customerId ?? '').isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a company first'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if ((selectedEmployeeId ?? '').isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an employee'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      isSaving = true;
                    });

                    try {
                      final selectedEmp = getSelectedEmployee();
                      final Map<String, dynamic> dataMap = {
                        'process': processCtrl.text,
                        'iqaNo': iqaCtrl.text,
                        'clause': clauseCtrl.text,
                        'ncrNo': ncrNoCtrl.text,
                        'statement': statementCtrl.text,
                        'evidence': evidenceCtrl.text,
                        'classification': classificationCtrl.text,
                        'dueDate': dueDateCtrl.text,
                        'correction': correctionCtrl.text,
                        'plannedDate': plannedDateCtrl.text,
                        'actualDate': actualDateCtrl.text,
                        'rootCause': rootCauseCtrl.text,
                        'correctiveAction': correctiveCtrl.text,
                        'verification': verificationCtrl.text,
                        'auditor': auditorCtrl.text,
                        'approvedBy': approvedCtrl.text,
                        'customerId': selectedCustomer?.customerId ?? '',
                        'companyName': selectedCustomer?.companyName ?? '',
                        'employeeId': selectedEmp?.userId ?? '',
                        'employeeName': selectedEmp?.userName ?? '',
                        'employeeEmail': selectedEmp?.email ?? '',
                        'status': currentStatus,
                      };

                      final hiveService = getIt<HiveService>();
                      UserModel? consultantUserModel = hiveService.getUser();

                      final assignedConsultantId = (selectedCustomer?.consultantId ?? '').isNotEmpty
                          ? selectedCustomer!.consultantId!
                          : (widget.ncrData?['consultantId'] ?? consultantUserModel?.userId ?? "");

                      dataMap['consultantId'] = assignedConsultantId;

                      Future<void> sendNcrEmails(bool isUpdate) async {
                        // 1. Notify Employee
                        if ((selectedEmp?.email ?? '').isNotEmpty) {
                          try {
                            await BrevoEmailService.sendNcrAssignedMail(
                              employeeEmail: selectedEmp!.email,
                              employeeName: selectedEmp!.userName,
                              companyName: selectedCustomer?.companyName ?? '',
                              ncrNo: ncrNoCtrl.text,
                              process: processCtrl.text,
                              isUpdate: isUpdate,
                            );
                          } catch (e) {
                            debugPrint("Failed to send NCR employee email notification: $e");
                          }
                        }

                        // 2. Notify Customer Contacts
                        if (selectedCustomer != null) {
                          final Set<String> customerEmails = {};
                          if ((selectedCustomer?.email ?? '').isNotEmpty) customerEmails.add(selectedCustomer!.email.trim());
                          if ((selectedCustomer?.topLevelEmail ?? '').isNotEmpty) customerEmails.add(selectedCustomer!.topLevelEmail.trim());
                          if ((selectedCustomer?.mediumLevelEmail ?? '').isNotEmpty) customerEmails.add(selectedCustomer!.mediumLevelEmail.trim());
                          if ((selectedCustomer?.lowLevelEmail ?? '').isNotEmpty) customerEmails.add(selectedCustomer!.lowLevelEmail.trim());

                          for (final custEmail in customerEmails) {
                            if (!Utility.emailValidationPattern(value: custEmail)) {
                              try {
                                await BrevoEmailService.sendNcrAssignedMail(
                                  employeeEmail: custEmail,
                                  employeeName: selectedCustomer?.companyName ?? 'Valued Customer',
                                  companyName: selectedCustomer?.companyName ?? '',
                                  ncrNo: ncrNoCtrl.text,
                                  process: processCtrl.text,
                                  isUpdate: isUpdate,
                                );
                              } catch (e) {
                                debugPrint("Failed to send NCR customer email notification to $custEmail: $e");
                              }
                            }
                          }
                        }
                      }

                      if (isReview) {
                        final docId = widget.ncrData?['id'];
                        if (docId != null) {
                          dataMap['updatedAt'] = Timestamp.now();
                          await _ncrRepository.updateNcrForm(docId, dataMap);
                          await sendNcrEmails(true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("NCR Updated Successfully")),
                            );
                            Navigator.pop(context);
                          }
                        }
                      } else {
                        if ((consultantUserModel?.userId ?? '').isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login first'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        dataMap['createdAt'] = Timestamp.now();

                        final model = NcrFormModel(
                          process: processCtrl.text,
                          iqaNo: iqaCtrl.text,
                          clause: clauseCtrl.text,
                          ncrNo: ncrNoCtrl.text,
                          statement: statementCtrl.text,
                          evidence: evidenceCtrl.text,
                          classification: classificationCtrl.text,
                          dueDate: dueDateCtrl.text,
                          correction: correctionCtrl.text,
                          plannedDate: plannedDateCtrl.text,
                          actualDate: actualDateCtrl.text,
                          rootCause: rootCauseCtrl.text,
                          correctiveAction: correctiveCtrl.text,
                          verification: verificationCtrl.text,
                          auditor: auditorCtrl.text,
                          approvedBy: approvedCtrl.text,
                          consultantId: assignedConsultantId,
                          companyId: selectedCustomer?.customerId ?? '',
                          employeeId: selectedEmp?.userId ?? '',
                          employeeName: selectedEmp?.userName ?? '',
                          employeeEmail: selectedEmp?.email ?? '',
                          status: currentStatus,
                          createdAt: Timestamp.now(),
                        );

                        await _ncrRepository.saveNcrForm(model);
                        await sendNcrEmails(false);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("NCR Saved Successfully")),
                          );
                          GoRouter.of(context).pop();
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Operation failed: $e")),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          isSaving = false;
                        });
                      }
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
