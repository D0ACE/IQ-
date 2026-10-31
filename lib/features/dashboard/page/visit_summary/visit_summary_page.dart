import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/model/visitor_summary_model.dart';


class ScopeReviewItem {
  final TextEditingController titleController;

  ScopeReviewItem({
    required String title,
  }) : titleController = TextEditingController(text: title);
}

class VisitorSummaryPage extends StatefulWidget {
  final VisitorSummaryModel? visitorSummaryModel; // 👈 ADD THIS

  const VisitorSummaryPage({super.key, this.visitorSummaryModel});

  @override
  State<VisitorSummaryPage> createState() => _VisitorSummaryPageState();
}

class _VisitorSummaryPageState extends State<VisitorSummaryPage> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // ================= VISIT DETAILS CONTROLLERS
  final locationCtrl = TextEditingController();
  final visitDateCtrl = TextEditingController();
  final loginTimeCtrl = TextEditingController();
  final logoutTimeCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  final consultantCoachCtrl = TextEditingController();
  CustomerModel? selectedCustomer;
  String selectedConsultantCoachName = '';

  final hiveService = getIt<HiveService>();
  UserModel? consultantUserModel;

  // ================= COMPLIANCE
  String complianceStatus = 'Fully Compliant';
  final complianceCommentsCtrl = TextEditingController();

  // ================= CLIENT FEEDBACK
  final clientFeedbackCtrl = TextEditingController();

  // ================= SIGN OFF
  final officerSignNameCtrl = TextEditingController();
  final clientRepNameCtrl = TextEditingController();
  final signDateCtrl = TextEditingController();

  // ================= SCOPE OF REVIEW
  final List<ScopeReviewItem> scopeItems = [];

  // ================= TABLE DATA
  final nonCompliances = <Map<String, TextEditingController>>[];
  final capas = <Map<String, dynamic>>[];

  final labelStyle = const TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  final hintStyle = TextStyle(color: Colors.grey.shade600);

  void addScopeItem() {
    setState(() {
      scopeItems.add(ScopeReviewItem(title: ''));
    });
  }

  void removeScopeItem(int index) {
    setState(() {
      scopeItems[index].titleController.dispose();
      scopeItems.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    consultantUserModel = hiveService.getUser();
    if (Utility.isConsultant(consultantUserModel?.roleId)) {
      selectedConsultantCoachName = consultantUserModel?.userName ?? '';
      consultantCoachCtrl.text = selectedConsultantCoachName;
      officerSignNameCtrl.text = selectedConsultantCoachName;
    } else if (widget.visitorSummaryModel != null) {
      selectedConsultantCoachName = widget.visitorSummaryModel!.consultantCoachName;
      consultantCoachCtrl.text = selectedConsultantCoachName;
      officerSignNameCtrl.text = widget.visitorSummaryModel!.signOff.consultantCoachName.isNotEmpty
          ? widget.visitorSummaryModel!.signOff.consultantCoachName
          : selectedConsultantCoachName;
    }
    addNonCompliance();
    addCapa();
    if (widget.visitorSummaryModel != null) {
      _prefillForUpdate();
    }
  }

  @override
  void dispose() {
    locationCtrl.dispose();
    visitDateCtrl.dispose();
    loginTimeCtrl.dispose();
    logoutTimeCtrl.dispose();
    purposeCtrl.dispose();
    departmentCtrl.dispose();
    consultantCoachCtrl.dispose();
    complianceCommentsCtrl.dispose();
    clientFeedbackCtrl.dispose();
    officerSignNameCtrl.dispose();
    clientRepNameCtrl.dispose();
    signDateCtrl.dispose();
    for (final item in scopeItems) {
      item.titleController.dispose();
    }
    for (final n in nonCompliances) {
      for (final c in n.values) {
        c.dispose();
      }
    }
    for (final c in capas) {
      c.forEach((key, value) {
        if (value is TextEditingController) {
          value.dispose();
        }
      });
    }
    super.dispose();
  }

  void _prefillForUpdate() {
    final m = widget.visitorSummaryModel!;

    locationCtrl.text = m.location;
    visitDateCtrl.text = m.visitDate ?? '';
    loginTimeCtrl.text = m.loginTime;
    logoutTimeCtrl.text = m.logoutTime;
    purposeCtrl.text = m.purpose;
    selectedConsultantCoachName = m.consultantCoachName;
    consultantCoachCtrl.text = m.consultantCoachName;
    departmentCtrl.text = m.department;

    complianceStatus = m.complianceStatus;
    complianceCommentsCtrl.text = m.complianceComments;
    clientFeedbackCtrl.text = m.clientFeedback;

    scopeItems.clear();
    if (m.scopeOfReview.isNotEmpty) {
      for (final item in m.scopeOfReview) {
        scopeItems.add(ScopeReviewItem(title: item));
      }
    }

    nonCompliances.clear();
    for (final n in m.nonCompliances) {
      nonCompliances.add({
        'gap': TextEditingController(text: n.gap),
        'category': TextEditingController(text: n.category.isNotEmpty ? n.category : 'Minor'),
        'actionRequired': TextEditingController(text: n.actionRequired),
        'responsible': TextEditingController(text: n.responsible),
        'targetDate': TextEditingController(text: n.targetDate ?? ''),
      });
    }

    capas.clear();
    for (final c in m.capas) {
      capas.add({
        'action': TextEditingController(text: c.action),
        'rootCause': TextEditingController(text: c.rootCause),
        'date': TextEditingController(text: c.date ?? ''),
        'actionTakenBy': TextEditingController(text: c.actionTakenBy),
        'evidence': TextEditingController(text: c.evidence),
        'pendingBytes': null,
        'pendingFileName': null,
      });
    }

    officerSignNameCtrl.text = m.signOff.consultantCoachName.isNotEmpty ? m.signOff.consultantCoachName : m.consultantCoachName;
    clientRepNameCtrl.text = m.signOff.clientName;
    signDateCtrl.text = m.signOff.signDate ?? '';
    fetchCustomer();
  }

  Future<void> fetchCustomer() async {
    final customerId = widget.visitorSummaryModel?.customerId ?? '';
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
      }
    } catch (e) {
      debugPrint('Error fetching customer for visit summary: $e');
    }
  }

  // ================= DATE & TIME PICKERS
  Future<void> _pickDate(TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    if (time != null) {
      final formattedTime = time.format(context);
      ctrl.text = formattedTime;
    }
  }

  Widget sectionCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  void addNonCompliance() => setState(
    () => nonCompliances.add({
      'gap': TextEditingController(),
      'category': TextEditingController(text: 'Minor'),
      'actionRequired': TextEditingController(),
      'responsible': TextEditingController(),
      'targetDate': TextEditingController(),
    }),
  );

  void addCapa() => setState(
    () => capas.add({
      'action': TextEditingController(),
      'rootCause': TextEditingController(),
      'date': TextEditingController(),
      'actionTakenBy': TextEditingController(),
      'evidence': TextEditingController(),
      'pendingBytes': null,
      'pendingFileName': null,
    }),
  );

  Future<void> _pickCapaEvidence(Map<String, dynamic> capaItem) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null && bytes.isNotEmpty) {
          setState(() {
            capaItem['pendingBytes'] = bytes;
            capaItem['pendingFileName'] = file.name;
            (capaItem['evidence'] as TextEditingController).text = file.name;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File "${file.name}" selected. Will be uploaded on form submit.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error selecting evidence file: $e');
    }
  }

  Future<Map<String, dynamic>> _buildPayloadWithUploads() async {
    final assignedConsultantId = (selectedCustomer?.consultantId ?? '').isNotEmpty
        ? selectedCustomer!.consultantId!
        : (widget.visitorSummaryModel?.consultantId ?? consultantUserModel?.userId ?? '');

    final List<String> scopeList = scopeItems
        .map((item) => item.titleController.text.trim())
        .where((title) => title.isNotEmpty)
        .toList();

    final supabase = Supabase.instance.client;

    final List<Map<String, String>> capasPayload = [];
    for (final c in capas) {
      String evidenceUrl = (c['evidence'] as TextEditingController).text.trim();
      final Uint8List? pendingBytes = c['pendingBytes'] as Uint8List?;
      final String? pendingFileName = c['pendingFileName'] as String?;

      if (pendingBytes != null && pendingFileName != null && pendingFileName.isNotEmpty) {
        final sanitizedFileName = pendingFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final String supabasePath = 'policies/capa_${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

        await supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
          supabasePath,
          pendingBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        evidenceUrl = supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);
      }

      capasPayload.add({
        'action': (c['action'] as TextEditingController).text,
        'rootCause': (c['rootCause'] as TextEditingController).text,
        'date': (c['date'] as TextEditingController).text,
        'actionTakenBy': (c['actionTakenBy'] as TextEditingController).text,
        'evidence': evidenceUrl,
      });
    }

    final coachName = consultantCoachCtrl.text.trim().isNotEmpty
        ? consultantCoachCtrl.text.trim()
        : selectedConsultantCoachName;

    return {
      'customerId': selectedCustomer?.customerId,
      'consultantId': assignedConsultantId,
      'location': locationCtrl.text.trim(),
      'visitDate': visitDateCtrl.text,
      'loginTime': loginTimeCtrl.text,
      'logoutTime': logoutTimeCtrl.text,
      'purpose': purposeCtrl.text,
      'consultantCoachName': coachName,
      'department': departmentCtrl.text,

      'scopeOfReview': scopeList,

      'observations': [],

      'complianceStatus': complianceStatus,
      'complianceComments': complianceCommentsCtrl.text,

      'nonCompliances': nonCompliances
          .map(
            (n) => {
              'gap': n['gap']!.text,
              'category': n['category']!.text,
              'actionRequired': n['actionRequired']!.text,
              'responsible': n['responsible']!.text,
              'targetDate': n['targetDate']!.text,
            },
          )
          .toList(),

      'capas': capasPayload,

      'clientFeedback': clientFeedbackCtrl.text,

      'signOff': {
        'consultantCoachName': officerSignNameCtrl.text.isNotEmpty ? officerSignNameCtrl.text : coachName,
        'officerSign': '',
        'clientName': clientRepNameCtrl.text,
        'clientSign': '',
        'signDate': signDateCtrl.text,
      },
    };
  }

  // ================= UI
  @override
  Widget build(BuildContext context) {
    final roleId = consultantUserModel?.roleId ?? '';
    final bool isAdminOrSuperAdmin = Utility.isAdmin(roleId) || Utility.isSuperAdmin(roleId);
    final bool isConsultant = Utility.isConsultant(roleId);

    return BlocConsumer<VisitorSummaryCubit, VisitorSummaryState>(
        listener: (context, state) {
          if (state is VisitorSummarySuccess) {
            setState(() {
              isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            GoRouter.of(context).pop();
          } else if (state is VisitorSummaryError) {
            setState(() {
              isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is VisitorSummaryLoading || isSubmitting;
          return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(title: Text(widget.visitorSummaryModel!=null?'Update Visitor Summary':'Create Visitor Summary')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      // ================= Select Company
                      sectionCard('Select Company', [
                        CustomerDropdownWidget(
                          selectedCustomer: selectedCustomer,
                          consultantId: isAdminOrSuperAdmin
                              ? null
                              : consultantUserModel?.userId,
                          onChanged: (customer) {
                            setState(() {
                              selectedCustomer = customer;
                            });
                          },
                        ),
                      ]),

                      // ================= VISIT DETAILS
                      sectionCard('Visit Details', [
                        AppTextFieldWidget(
                          labelText: 'Client Location / Site',
                          labelTextStyle: labelStyle,
                          textFieldController: locationCtrl,
                          validator: (v) => requiredValidator(v, 'Location'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Date of Visit',
                          readOnly: true,
                          onTap: () => _pickDate(visitDateCtrl),
                          suffixIconWidget: const Icon(Icons.calendar_today),
                          labelTextStyle: labelStyle,
                          textFieldController: visitDateCtrl,
                          validator: (v) => requiredValidator(v, 'Visit Date'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextFieldWidget(
                                labelText: 'Login Time',
                                readOnly: true,
                                onTap: () => _pickTime(loginTimeCtrl),
                                suffixIconWidget: const Icon(Icons.access_time),
                                labelTextStyle: labelStyle,
                                textFieldController: loginTimeCtrl,
                                validator: (v) => requiredValidator(v, 'Login Time'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextFieldWidget(
                                labelText: 'Logout Time',
                                readOnly: true,
                                onTap: () => _pickTime(logoutTimeCtrl),
                                suffixIconWidget: const Icon(Icons.access_time),
                                labelTextStyle: labelStyle,
                                textFieldController: logoutTimeCtrl,
                                validator: (v) => requiredValidator(v, 'Logout Time'),
                              ),
                            ),
                          ],
                        ),
                        AppTextFieldWidget(
                          labelText: 'Purpose of Visit',
                          labelTextStyle: labelStyle,
                          textFieldController: purposeCtrl,
                          validator: (v) => requiredValidator(v, 'Purpose'),
                        ),

                        // ================= CONSULTANT COACH NAME DROPDOWN =================
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Consultant Coach Name',
                            style: labelStyle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        BlocProvider(
                          create: (_) => getIt<ConsultantCubit>()..fetchConsultants(),
                          child: BlocBuilder<ConsultantCubit, ConsultantState>(
                            builder: (context, consultantState) {
                              if (consultantState is ConsultantLoading) {
                                return const LinearProgressIndicator();
                              }
                              if (consultantState is ConsultantLoaded) {
                                final consultants = consultantState.consultants;

                                if (selectedConsultantCoachName.isEmpty && isConsultant && consultants.isNotEmpty) {
                                  selectedConsultantCoachName = consultantUserModel?.userName ?? consultants.first.userName;
                                  consultantCoachCtrl.text = selectedConsultantCoachName;
                                  if (officerSignNameCtrl.text.isEmpty) {
                                    officerSignNameCtrl.text = selectedConsultantCoachName;
                                  }
                                }

                                String? dropdownValue;
                                if (consultants.any((c) => c.userName == selectedConsultantCoachName)) {
                                  dropdownValue = selectedConsultantCoachName;
                                } else if (isConsultant && consultants.isNotEmpty) {
                                  dropdownValue = consultantUserModel?.userName ?? consultants.first.userName;
                                  selectedConsultantCoachName = dropdownValue;
                                  consultantCoachCtrl.text = dropdownValue;
                                } else {
                                  dropdownValue = null;
                                }

                                return DropdownButtonFormField<String>(
                                  value: dropdownValue,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    hintText: 'Select Consultant Coach',
                                  ),
                                  items: consultants.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c.userName,
                                      child: Text(c.userName),
                                    );
                                  }).toList(),
                                  onChanged: isConsultant
                                      ? null // If consultant, default selected and locked
                                      : (v) {
                                          if (v != null) {
                                            setState(() {
                                              selectedConsultantCoachName = v;
                                              consultantCoachCtrl.text = v;
                                              officerSignNameCtrl.text = v;
                                            });
                                          }
                                        },
                                  validator: (v) => requiredValidator(v, 'Consultant Coach Name'),
                                );
                              }
                              return AppTextFieldWidget(
                                labelText: 'Consultant Coach Name',
                                labelTextStyle: labelStyle,
                                textFieldController: consultantCoachCtrl,
                                readOnly: isConsultant,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        AppTextFieldWidget(
                          labelText: 'Department / Process Audited',
                          labelTextStyle: labelStyle,
                          textFieldController: departmentCtrl,
                          validator: (v) => requiredValidator(v, 'Department'),
                        ),
                      ]),

                      // ================= SCOPE OF REVIEW
                      sectionCard('Scope of Review', [
                        if (scopeItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No scope items added yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ...scopeItems.asMap().entries.map(
                          (entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppTextFieldWidget(
                                        labelText: 'Scope Item ${index + 1}',
                                        hintText: 'Enter scope item name',
                                        labelTextStyle: labelStyle,
                                        textFieldController: item.titleController,
                                        validator: (v) => requiredValidator(v, 'Scope Item Name'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => removeScopeItem(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: addScopeItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Scope Item'),
                          ),
                        ),
                      ]),

                      // ================= COMPLIANCE STATUS
                      sectionCard('Compliance Status', [
                        DropdownButtonFormField<String>(
                          initialValue: complianceStatus,
                          validator: (v) => dropdownValidator(v, 'Compliance Status'),
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Fully Compliant',
                              child: Text('Fully Compliant'),
                            ),
                            DropdownMenuItem(
                              value: 'Partially Compliant',
                              child: Text('Partially Compliant'),
                            ),
                            DropdownMenuItem(
                              value: 'Non-Compliant',
                              child: Text('Non-Compliant'),
                            ),
                          ],
                          onChanged: (v) => setState(() => complianceStatus = v!),
                        ),
                        const SizedBox(height: 12),
                        AppTextFieldWidget(
                          labelText: 'Comments',
                          maxLines: 3,
                          labelTextStyle: labelStyle,
                          textFieldController: complianceCommentsCtrl,
                          validator: (v) => requiredValidator(v, 'Comments'),
                        ),
                      ]),

                      // ================= NON-COMPLIANCE / GAPS
                      sectionCard('Non-Compliance / Gaps', [
                        ...nonCompliances.asMap().entries.map(
                          (e) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'NC #${e.key + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => setState(() => nonCompliances.removeAt(e.key)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Description of NC',
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['gap']!,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: ['Minor', 'Major', 'OFI'].contains(e.value['category']!.text)
                                              ? e.value['category']!.text
                                              : 'Minor',
                                          decoration: InputDecoration(
                                            labelText: 'Category of NC',
                                            labelStyle: labelStyle,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                                            DropdownMenuItem(value: 'Major', child: Text('Major')),
                                            DropdownMenuItem(value: 'OFI', child: Text('OFI')),
                                          ],
                                          onChanged: (v) {
                                            if (v != null) {
                                              setState(() => e.value['category']!.text = v);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Action Required',
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['actionRequired']!,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Responsible',
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['responsible']!,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppTextFieldWidget(
                                    labelText: 'Target Date',
                                    readOnly: true,
                                    onTap: () => _pickDate(e.value['targetDate']!),
                                    suffixIconWidget: const Icon(Icons.calendar_today),
                                    labelTextStyle: labelStyle,
                                    textFieldController: e.value['targetDate']!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: addNonCompliance,
                          icon: const Icon(Icons.add),
                          label: const Text('Add NC'),
                        ),
                      ]),

                      // ================= CAPA
                      sectionCard('CAPA', [
                        ...capas.asMap().entries.map(
                          (e) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'CAPA #${e.key + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => setState(() => capas.removeAt(e.key)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Action Taken',
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['action']!,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Root Cause',
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['rootCause']!,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Date of Action Taken',
                                          readOnly: true,
                                          onTap: () => _pickDate(e.value['date']!),
                                          suffixIconWidget: const Icon(Icons.calendar_today),
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['date']!,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: AppTextFieldWidget(
                                          labelText: 'Action Taken By',
                                          labelTextStyle: labelStyle,
                                          textFieldController: e.value['actionTakenBy']!,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppTextFieldWidget(
                                    labelText: 'Supporting Evidence',
                                    hintText: 'Upload document or file',
                                    readOnly: true,
                                    onTap: () => _pickCapaEvidence(e.value),
                                    suffixIconWidget: IconButton(
                                      icon: const Icon(Icons.attach_file, color: AppColors.kPrimaryColor),
                                      onPressed: () => _pickCapaEvidence(e.value),
                                    ),
                                    labelTextStyle: labelStyle,
                                    textFieldController: e.value['evidence']!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: addCapa,
                          icon: const Icon(Icons.add),
                          label: const Text('Add CAPA'),
                        ),
                      ]),

                      // ================= CLIENT FEEDBACK
                      sectionCard('Client Feedback', [
                        AppTextFieldWidget(
                          labelText: 'Remarks',
                          maxLines: 3,
                          labelTextStyle: labelStyle,
                          textFieldController: clientFeedbackCtrl,
                          validator: (v) => requiredValidator(v, 'Client Feedback'),
                        ),
                      ]),

                      // ================= SIGN OFF
                      sectionCard('Sign-Off', [
                        AppTextFieldWidget(
                          labelText: 'Consultant Coach Name',
                          labelTextStyle: labelStyle,
                          textFieldController: officerSignNameCtrl,
                          readOnly: isConsultant,
                          validator: (v) => requiredValidator(v, 'Consultant Coach Name'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Client Representative Name',
                          labelTextStyle: labelStyle,
                          textFieldController: clientRepNameCtrl,
                          validator: (v) => requiredValidator(v, 'Client Name'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Date',
                          readOnly: true,
                          onTap: () => _pickDate(signDateCtrl),
                          suffixIconWidget: const Icon(Icons.calendar_today),
                          labelTextStyle: labelStyle,
                          textFieldController: signDateCtrl,
                          validator: (v) => requiredValidator(v, 'Sign Date'),
                        ),
                      ]),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;

                                if (!areTablesValid()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please complete all table rows')),
                                  );
                                  return;
                                }
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

                                setState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  final payload = await _buildPayloadWithUploads();

                                  if (!mounted) return;

                                  if (widget.visitorSummaryModel != null && context.mounted) {
                                    context.read<VisitorSummaryCubit>().updateVisitorSummary(
                                          docId: widget.visitorSummaryModel?.id ?? '',
                                          payload: payload,
                                          selectedCustomer: selectedCustomer,
                                          consultantUserModel: consultantUserModel,
                                        );
                                  } else {
                                    if(context.mounted) {
                                      context.read<VisitorSummaryCubit>().createVisitorSummary(
                                          payload: payload,
                                          selectedCustomer: selectedCustomer,
                                          consultantUserModel: consultantUserModel,
                                        );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Error uploading files / submitting summary: $e');
                                  if (mounted) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error uploading files: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonDarkGreen,
                          disabledBackgroundColor:
                              AppColors.buttonDarkGreen.withValues(alpha: 0.6),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.buttonYellow,
                                ),
                              )
                            : Text(
                                widget.visitorSummaryModel != null
                                    ? 'Update Summary'
                                    : 'Submit Summary',
                                style: const TextStyle(
                                  color: AppColors.buttonYellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // ================= VALIDATORS
  String? requiredValidator(String? v, String label) {
    if (v == null || v.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? dropdownValidator(String? v, String label) {
    if (v == null || v.isEmpty) {
      return 'Please select $label';
    }
    return null;
  }

  bool isScopeValid() {
    return scopeItems.any((item) => item.titleController.text.trim().isNotEmpty);
  }

  bool areTablesValid() {
    for (final s in scopeItems) {
      if (s.titleController.text.trim().isEmpty) return false;
    }
    for (final n in nonCompliances) {
      if (n['gap']!.text.trim().isEmpty) return false;
    }
    for (final c in capas) {
      if (c['action']!.text.trim().isEmpty) return false;
    }
    return true;
  }
}
