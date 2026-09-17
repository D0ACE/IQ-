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
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
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
  final docNoCtrl = TextEditingController();
  final revNoCtrl = TextEditingController();
  final issueDateCtrl = TextEditingController();
  final pageCtrl = TextEditingController();

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

  CustomerModel? selectedCustomer;
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
      docNoCtrl.text = ncr['docNo'] ?? '';
      revNoCtrl.text = ncr['revNo'] ?? '';
      issueDateCtrl.text = ncr['issueDate'] ?? '';
      pageCtrl.text = ncr['page'] ?? '';
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
      currentStatus = ncr['status'];

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
    docNoCtrl.dispose();
    revNoCtrl.dispose();
    issueDateCtrl.dispose();
    pageCtrl.dispose();
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
    final doc = await getIt<FirebaseFirestore>()
        .collection('customers')
        .doc(widget.ncrData?['customerId'] ?? '')
        .get();

    setState(() {
      selectedCustomer = CustomerModel.fromJson(
        doc.data()!,
        customerId: widget.ncrData?['customerId'] ?? '',
      );
    });
  }

  void fetchUserRole() {
    roleId = userLoginDetails?.roleId ?? customerLoginDetails?.roleId ?? '';
    isRoleLoaded = true;
    if (isReview) {
      isEditable = widget.forceEdit && !Utility.isCustomer(roleId);
    }
    setState(() {});
  }

  Future<void> _updateStatus(String newStatus) async {
    final docId = widget.ncrData?['id'];
    if (docId == null) return;

    await _ncrRepository.updateNcrStatus(docId, newStatus);

    if (!mounted) return;
    setState(() {
      currentStatus = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Status updated to ${newStatus.toUpperCase()}")),
    );
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyBorderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LOGO
                  GestureDetector(
                    onTap: pickLogo,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.greyBorderColor),
                      ),
                      child: logo == null
                          ? const Center(
                              child: Text(
                                "Upload\nLogo",
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Image.file(logo!, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// TITLE
                  const Expanded(
                    child: Text(
                      "Internal Quality Audit\nNon Conformity Report (NCR)\n(System / Process)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// RIGHT SIDE FIELDS
                  SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        AppTextFieldWidget(
                          hintText: "DOC NO",
                          textFieldController: docNoCtrl,
                          readOnly: !isEditable,
                        ),
                        const SizedBox(height: 6),
                        AppTextFieldWidget(
                          hintText: "REV NO",
                          textFieldController: revNoCtrl,
                          readOnly: !isEditable,
                        ),
                        const SizedBox(height: 6),
                        AppTextFieldWidget(
                          hintText: "Issue Date",
                          textFieldController: issueDateCtrl,
                          readOnly: true,
                          onTap: () => isEditable ? pickDate(issueDateCtrl) : null,
                        ),
                        const SizedBox(height: 6),
                        AppTextFieldWidget(
                          hintText: "PAGE",
                          textFieldController: pageCtrl,
                          readOnly: !isEditable,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// 🔹 STATUS DISPLAY
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: currentStatus == AppConst.openNCRStatusKey
                    ? AppColors.orange.withValues(alpha: 0.2)
                    : currentStatus == AppConst.inProgressNCRStatusKey
                    ? AppColors.blue.withValues(alpha: 0.2)
                    : AppColors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Status: ${Utility.getNCRStatus(currentStatus)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: currentStatus == AppConst.openNCRStatusKey
                      ? AppColors.orange
                      : currentStatus == AppConst.inProgressNCRStatusKey
                      ? AppColors.blue
                      : AppColors.green,
                ),
              ),
            ),

            /// Status Buttons (Consultant Only)
            if (isReview && isRoleLoaded && Utility.isConsultant(roleId)) ...[
              const SizedBox(height: 20),

              Row(
                children: [
                  // OPEN → IN PROGRESS
                  if (currentStatus == AppConst.openNCRStatusKey)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _updateStatus(AppConst.inProgressNCRStatusKey);
                        },
                        child: const Text('Mark In Progress'),
                      ),
                    ),

                  // IN PROGRESS → CLOSED
                  if (currentStatus == AppConst.inProgressNCRStatusKey)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
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
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Yes"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _updateStatus(AppConst.closedNCRStatusKey);
                          }
                        },
                        child: const Text('Close NCR'),
                      ),
                    ),
                ],
              ),
            ],

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
                });

                /// 🔥 FULL MODEL AVAILABLE
                debugPrint('Customer ID: ${customer?.customerId}');
                debugPrint('Top Dept Email: ${customer?.topLevelEmail}');
              },
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
                        text: selectedCustomer?.lowLevelMobile ?? "",
                      ),
                    ),
                    readOnly: true,
                    isEnabled: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

                    setState(() {
                      isSaving = true;
                    });

                    try {
                      final Map<String, dynamic> dataMap = {
                        'docNo': docNoCtrl.text,
                        'revNo': revNoCtrl.text,
                        'issueDate': issueDateCtrl.text,
                        'page': pageCtrl.text,
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
                        'status': currentStatus,
                      };

                      if (isReview) {
                        final docId = widget.ncrData?['id'];
                        if (docId != null) {
                          dataMap['updatedAt'] = Timestamp.now();
                          await _ncrRepository.updateNcrForm(docId, dataMap);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("NCR Updated Successfully")),
                            );
                            GoRouter.of(context).pop();
                          }
                        }
                      } else {
                        final hiveService = getIt<HiveService>();
                        UserModel? consultantUserModel = hiveService.getUser();
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

                        dataMap['consultantId'] = consultantUserModel?.userId ?? "";
                        dataMap['createdAt'] = Timestamp.now();

                        final model = NcrFormModel(
                          docNo: docNoCtrl.text,
                          revNo: revNoCtrl.text,
                          issueDate: issueDateCtrl.text,
                          page: pageCtrl.text,
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
                        consultantId: consultantUserModel?.userId ?? "",
                        companyId: selectedCustomer?.customerId ?? '',
                        status: currentStatus,
                        createdAt: Timestamp.now(),
                      );

                        await _ncrRepository.saveNcrForm(model);

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
