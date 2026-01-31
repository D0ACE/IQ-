import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/constants/user_role.dart';
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
  const NCRFormPage({super.key, this.ncrData});

  @override
  State<NCRFormPage> createState() => _NCRFormPageState();
}

class _NCRFormPageState extends State<NCRFormPage> {
  File? logo;
  final picker = ImagePicker();
  final NcrRepository _ncrRepository = NcrRepository();
  late bool isReview;
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
  final CustomerModel? customerLoginDetails = getIt<HiveService>().getCustomer();

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


    //  fetchCustomer();
      /// Fetch user role from Firebase
      fetchUserRole();
  }}

  Future<void> fetchCustomer() async {
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.ncrData?['customerId'] ?? '')
        .get();

    setState(() {
      selectedCustomer = CustomerModel.fromJson(doc.data()!,customerId: widget.ncrData?['customerId'] ?? '');
    });
    print(selectedCustomer);
  }

  void fetchUserRole()  {
      roleId = userLoginDetails?.roleId??customerLoginDetails?.roleId??'';
      isRoleLoaded = true;
  }

  Future<void> _updateStatus(String newStatus) async {
    final docId = widget.ncrData?['id'];
    if (docId == null) return;

    await _ncrRepository.updateNcrStatus(docId, newStatus);

    setState(() {
      currentStatus = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Status updated to ${newStatus.toUpperCase()}")),
    );
  }

  /// 🔹 Date Picker
  Future<void> pickDate(TextEditingController controller) async {
    if (isReview) return; // Prevent editing in review mode
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
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

  /// 🔹 Status Button Widget
  // Widget _statusButton(String value, String label) {
  //   final isActive = currentStatus == value;

  //   return Expanded(
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: isActive
  //             ? value == AppConst.openNCRStatusKey
  //                   ? AppColors.orange
  //                   : value == AppConst.inProgressNCRStatusKey
  //                   ? AppColors.blue
  //                   : AppColors.green
  //             : AppColors.greyTextFormFiledColor,
  //       ),
  //       onPressed: () async {
  //         final docId = widget.ncrData?['id'];
  //         if (docId == null) return;

  //         await _ncrRepository.updateNcrStatus(docId, value);

  //         setState(() {
  //           currentStatus = value;
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Status updated to ${value.toUpperCase()}")),
  //         );
  //       },

  //       child: Text(
  //         label,
  //         style: TextStyle(
  //           color: isActive ? Colors.white : AppColors.blackTextColor,
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _statusButton(String value, String label) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        onPressed: () async {
          await _updateStatus(value);
        },
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isReview ? "View NCR" : "NCR Form")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔹 HEADER
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyBorderColor!),
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
                        border: Border.all(color: AppColors.greyBorderColor!),
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
                          readOnly: isReview,
                        ),
                        const SizedBox(height: 6),
                        AppTextFieldWidget(
                          hintText: "REV NO",
                          textFieldController: revNoCtrl,
                          readOnly: isReview,
                        ),
                        const SizedBox(height: 6),
                        AppTextFieldWidget(
                          hintText: "Issue Date",
                          textFieldController: issueDateCtrl,
                          readOnly: true,
                          onTap: () => pickDate(issueDateCtrl),
                        ),
                        const SizedBox(height: 6),
                        AppTextFieldWidget(
                          hintText: "PAGE",
                          textFieldController: pageCtrl,
                          readOnly: isReview,
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
                    ? AppColors.orange.withOpacity(0.2)
                    : currentStatus == AppConst.inProgressNCRStatusKey
                    ? AppColors.blue.withOpacity(0.2)
                    : AppColors.green.withOpacity(0.2),
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
            if (isReview &&
                isRoleLoaded &&
                roleId == UserRole.consultant) ...[
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
              selectedCustomer: selectedCustomer,
              readOnly: Utility.isCustomer(roleId),
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
                    readOnly: isReview,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "IQA Number",
                    textFieldController: iqaCtrl,
                    readOnly: isReview,
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
                    readOnly: isReview,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "NCR Number & Date",
                    textFieldController: ncrNoCtrl,
                    readOnly: isReview,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Statement of Non Conformity",
              maxLines: 2,
              textFieldController: statementCtrl,
              readOnly: isReview,
            ),

            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Objective Evidence",
              textFieldController: evidenceCtrl,
              readOnly: isReview,
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Classification",
                    textFieldController: classificationCtrl,
                    readOnly: isReview,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Due Date",
                    textFieldController: dueDateCtrl,
                    readOnly: true,
                    onTap: () => pickDate(dueDateCtrl),
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
              readOnly: isReview,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Planned Completion Date",
                    textFieldController: plannedDateCtrl,
                    readOnly: true,
                    onTap: () => pickDate(plannedDateCtrl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Actual Completion Date",
                    textFieldController: actualDateCtrl,
                    readOnly: true,
                    onTap: () => pickDate(actualDateCtrl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Root Cause",
              maxLines: 2,
              textFieldController: rootCauseCtrl,
              readOnly: isReview,
            ),
            const SizedBox(height: 8),
            AppTextFieldWidget(
              hintText: "Corrective Actions",
              maxLines: 2,
              textFieldController: correctiveCtrl,
              readOnly: isReview,
            ),

            /// 🔹 SECTION 3
            sectionHeader("SECTION 3 – VERIFICATION"),
            AppTextFieldWidget(
              hintText: "Verification Details",
              maxLines: 2,
              textFieldController: verificationCtrl,
              readOnly: isReview,
            ),

            /// 🔹 SECTION 4
            sectionHeader("SECTION 4 – NCR CLOSURE"),
            Row(
              children: [
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Auditor Name / Date",
                    textFieldController: auditorCtrl,
                    readOnly: isReview,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextFieldWidget(
                    hintText: "Approved by MR",
                    textFieldController: approvedCtrl,
                    readOnly: isReview,
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

            /// 🔹 SAVE BUTTON
            if (!isReview)
              GradientButton(
                text: "Save NCR",
                radiusSize: 50,
                onPressed: () async {
                  final hiveService = getIt<HiveService>();
                  UserModel? consultantUserModel = hiveService.getUser();
                  print("Consultant ${consultantUserModel?.userId}");
                  if ((selectedCustomer?.customerId ?? '').isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a company first'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  } else if ((consultantUserModel?.userId ?? '').isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login first'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

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

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("NCR Saved Successfully")),
                  );
                  GoRouter.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
