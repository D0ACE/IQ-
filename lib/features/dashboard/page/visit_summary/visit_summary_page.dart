import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/model/visitor_summary_model.dart';


class VisitorSummaryPage extends StatefulWidget {
  final VisitorSummaryModel? visitorSummaryModel; // 👈 ADD THIS

  const VisitorSummaryPage({super.key, this.visitorSummaryModel});

  @override
  State<VisitorSummaryPage> createState() => _VisitorSummaryPageState();
}

class _VisitorSummaryPageState extends State<VisitorSummaryPage> {
  final _formKey = GlobalKey<FormState>();

  // ================= VISIT DETAILS CONTROLLERS
  final clientNameCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final visitDateCtrl = TextEditingController();
  final fromTimeCtrl = TextEditingController();
  final toTimeCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final officerCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  CustomerModel? selectedCustomer;

  final hiveService = getIt<HiveService>();
  UserModel? consultantUserModel;

  Map<String, dynamic> _buildPayload() {
    return {
      'customerId': selectedCustomer?.customerId,
      'consultantId': consultantUserModel?.userId,
      'clientName': clientNameCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      'visitDate': visitDateCtrl.text,
      'fromTime': fromTimeCtrl.text,
      'toTime': toTimeCtrl.text,
      'purpose': purposeCtrl.text,
      'officerName': officerCtrl.text,
      'department': departmentCtrl.text,

      'scopeOfReview': scopeReview,

      'observations': observations
          .map(
            (o) => {
              'obs': o['obs']!.text,
              'process': o['process']!.text,
              'severity': o['severity']!.text,
            },
          )
          .toList(),

      'complianceStatus': complianceStatus,
      'complianceComments': complianceCommentsCtrl.text,

      'nonCompliances': nonCompliances
          .map(
            (n) => {
              'gap': n['gap']!.text,
              'root': n['root']!.text,
              'impact': n['impact']!.text,
            },
          )
          .toList(),

      'capas': capas
          .map(
            (c) => {
              'action': c['action']!.text,
              'owner': c['owner']!.text,
              'date': c['date']!.text,
            },
          )
          .toList(),

      'clientFeedback': clientFeedbackCtrl.text,
      'overallAssessment': overallAssessment,

      'signOff': {
        'officerName': officerSignNameCtrl.text,
        'officerSign': officerSignCtrl.text,
        'clientName': clientRepNameCtrl.text,
        'clientSign': clientRepSignCtrl.text,
        'signDate': signDateCtrl.text,
      },
    };
  }

  // ================= COMPLIANCE
  String complianceStatus = 'Fully Compliant';
  final complianceCommentsCtrl = TextEditingController();

  // ================= CLIENT FEEDBACK
  final clientFeedbackCtrl = TextEditingController();

  // ================= OVERALL ASSESSMENT
  String overallAssessment = 'Satisfactory';

  // ================= SIGN OFF
  final officerSignNameCtrl = TextEditingController();
  final officerSignCtrl = TextEditingController();
  final clientRepNameCtrl = TextEditingController();
  final clientRepSignCtrl = TextEditingController();
  final signDateCtrl = TextEditingController();

  // ================= SCOPE OF REVIEW
  final Map<String, String> scopeReview = {
    'Process Adherence': 'No',
    'Documentation': 'No',
    'Regulatory Compliance': 'No',
    'SOP Adherence': 'No',
    'Data Security / Controls': 'No',
    'Others': 'No',
  };

  // ================= TABLE DATA
  final observations = <Map<String, TextEditingController>>[];
  final nonCompliances = <Map<String, TextEditingController>>[];
  final capas = <Map<String, TextEditingController>>[];

  final labelStyle = const TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  final hintStyle = TextStyle(color: Colors.grey.shade600);

  @override
  void initState() {
    super.initState();
    consultantUserModel=hiveService.getUser();
    addObservation();
    addNonCompliance();
    addCapa();
    if(widget.visitorSummaryModel!=null){
      _prefillForUpdate();
    }
  }

  void _prefillForUpdate() {
    final m = widget.visitorSummaryModel!;

    clientNameCtrl.text = m.clientName;
    locationCtrl.text = m.location;
    visitDateCtrl.text = m.visitDate ?? '';
    fromTimeCtrl.text = m.fromTime;
    toTimeCtrl.text = m.toTime;
    purposeCtrl.text = m.purpose;
    officerCtrl.text = m.officerName;
    departmentCtrl.text = m.department;

    complianceStatus = m.complianceStatus;
    complianceCommentsCtrl.text = m.complianceComments;
    clientFeedbackCtrl.text = m.clientFeedback;
    overallAssessment = m.overallAssessment;

    scopeReview.clear();
    scopeReview.addAll(
      m.scopeOfReview.map((k, v) => MapEntry(k, v.toString())),
    );

    observations.clear();
    for (final o in m.observations) {
      observations.add({
        'obs': TextEditingController(text: o.obs),
        'process': TextEditingController(text: o.process),
        'severity': TextEditingController(text: o.severity),
      });
    }

    nonCompliances.clear();
    for (final n in m.nonCompliances) {
      nonCompliances.add({
        'gap': TextEditingController(text: n.gap),
        'root': TextEditingController(text: n.root),
        'impact': TextEditingController(text: n.impact),
      });
    }

    capas.clear();
    for (final c in m.capas) {
      capas.add({
        'action': TextEditingController(text: c.action),
        'owner': TextEditingController(text: c.owner),
        'date': TextEditingController(text: c.date ?? ''),
      });
    }

    officerSignNameCtrl.text = m.signOff.officerName;
    officerSignCtrl.text = m.signOff.officerSign;
    clientRepNameCtrl.text = m.signOff.clientName;
    clientRepSignCtrl.text = m.signOff.clientSign;
    signDateCtrl.text = m.signOff.signDate ?? '';
    fetchCustomer();
    //selectedCustomer = CustomerModel(customerId: m.customerId);
  }

  Future<void> fetchCustomer() async {
    final doc = await getIt<FirebaseFirestore>()
        .collection('customers')
        .doc(widget.visitorSummaryModel?.customerId ?? '')
        .get();

    setState(() {
      selectedCustomer = CustomerModel.fromJson(
        doc.data()!,
        customerId: widget.visitorSummaryModel?.customerId ?? '',
      );
    });
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
    // Save ISO format for easier Firestore parsing
    ctrl.text = DateFormat('yyyy-MM-dd').format(date); // e.g., 2026-01-10
  }
}

  Future<void> _pickTime(TextEditingController ctrl) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) ctrl.text = time.format(context);
  }

  // ================= TABLE HELPERS
  Widget tableHeader(List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text('Sl', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...titles.map(
            (t) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget tableRow({
    required int index,
    required List<Widget> fields,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ...fields.map(
            (f) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: f,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
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

  // ================= ADD ROWS
  void addObservation() => setState(
    () => observations.add({
      'obs': TextEditingController(),
      'process': TextEditingController(),
      'severity': TextEditingController(),
    }),
  );

  void addNonCompliance() => setState(
    () => nonCompliances.add({
      'gap': TextEditingController(),
      'root': TextEditingController(),
      'impact': TextEditingController(),
    }),
  );

  void addCapa() => setState(
    () => capas.add({
      'action': TextEditingController(),
      'owner': TextEditingController(),
      'date': TextEditingController(),
    }),
  );

  // ================= UI
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VisitorSummaryCubit, VisitorSummaryState>(
        listener: (context, state) {
          if (state is VisitorSummarySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            GoRouter.of(context).pop();
          } else if (state is VisitorSummaryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(title:  Text(widget.visitorSummaryModel!=null?'Update Visitor Summary':'Create Visitor Summary')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child:  Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      // ================= Select Company
                      sectionCard('Select Company', [
                        CustomerDropdownWidget(
                          selectedCustomer: selectedCustomer,
                          consultantId: consultantUserModel?.userId,
                          onChanged: (customer) {
                            setState(() {
                              selectedCustomer = customer;
                            });

                            /// 🔥 FULL MODEL AVAILABLE
                            debugPrint('Customer ID: ${customer?.customerId}');
                            debugPrint('Top Dept Email: ${customer?.topLevelEmail}');
                          },
                        ),
                      ]),

                      // ================= VISIT DETAILS
                      sectionCard('Visit Details', [
                        AppTextFieldWidget(
                          labelText: 'Client Name',
                          hintText: 'Enter client name',
                          labelTextStyle: labelStyle,
                          hintTextStyle: hintStyle,
                          textFieldController: clientNameCtrl,
                          validator: (v) => requiredValidator(v, 'Client Name'),
                        ),
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
                                labelText: 'From Time',
                                readOnly: true,
                                onTap: () => _pickTime(fromTimeCtrl),
                                suffixIconWidget: const Icon(Icons.access_time),
                                labelTextStyle: labelStyle,
                                textFieldController: fromTimeCtrl,
                                validator: (v) => requiredValidator(v, 'From Time'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextFieldWidget(
                                labelText: 'To Time',
                                readOnly: true,
                                onTap: () => _pickTime(toTimeCtrl),
                                suffixIconWidget: const Icon(Icons.access_time),
                                labelTextStyle: labelStyle,
                                textFieldController: toTimeCtrl,
                                validator: (v) => requiredValidator(v, 'To Time'),
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
                        AppTextFieldWidget(
                          labelText: 'Compliance Officer Name',
                          labelTextStyle: labelStyle,
                          textFieldController: officerCtrl,
                          validator: (v) => requiredValidator(v, 'Officer Name'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Department / Process Audited',
                          labelTextStyle: labelStyle,
                          textFieldController: departmentCtrl,
                          validator: (v) => requiredValidator(v, 'Department'),
                        ),
                      ]),

                      // ================= SCOPE OF REVIEW
                      // ================= SCOPE OF REVIEW (RADIO BUTTONS)
                      sectionCard('Scope of Review', [
                        ...scopeReview.keys.map(
                          (k) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(k, style: labelStyle),
                              Row(
                                children: ['Yes', 'No'].map((option) {
                                  return Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(option),
                                      value: option,
                                      groupValue: scopeReview[k],
                                      onChanged: (v) =>
                                          setState(() => scopeReview[k] = v!),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ]),
                      // ================= OBSERVATIONS
                      sectionCard('Observations', [
                        tableHeader([
                          'Observation / Finding',
                          'Process / Area',
                          'Severity',
                        ]),
                        ...observations.asMap().entries.map(
                          (e) => tableRow(
                            index: e.key,
                            fields: [
                              AppTextFieldWidget(
                                textFieldController: e.value['obs']!,
                              ),
                              AppTextFieldWidget(
                                textFieldController: e.value['process']!,
                              ),
                              AppTextFieldWidget(
                                textFieldController: e.value['severity']!,
                              ),
                            ],
                            onRemove: () =>
                                setState(() => observations.removeAt(e.key)),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addObservation,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Observation'),
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
                        tableHeader(['Description of Gap', 'Root Cause', 'Impact']),
                        ...nonCompliances.asMap().entries.map(
                          (e) => tableRow(
                            index: e.key,
                            fields: [
                              AppTextFieldWidget(
                                textFieldController: e.value['gap']!,
                              ),
                              AppTextFieldWidget(
                                textFieldController: e.value['root']!,
                              ),
                              AppTextFieldWidget(
                                textFieldController: e.value['impact']!,
                              ),
                            ],
                            onRemove: () =>
                                setState(() => nonCompliances.removeAt(e.key)),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addNonCompliance,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Gap'),
                        ),
                      ]),

                      // ================= CAPA
                      sectionCard('CAPA', [
                        tableHeader([
                          'Action Required',
                          'Responsible',
                          'Target Date',
                        ]),
                        ...capas.asMap().entries.map(
                          (e) => tableRow(
                            index: e.key,
                            fields: [
                              AppTextFieldWidget(
                                textFieldController: e.value['action']!,
                              ),
                              AppTextFieldWidget(
                                textFieldController: e.value['owner']!,
                              ),
                              AppTextFieldWidget(
                                readOnly: true,
                                onTap: () => _pickDate(e.value['date']!),
                                suffixIconWidget: const Icon(Icons.calendar_today),
                                textFieldController: e.value['date']!,
                              ),
                            ],
                            onRemove: () => setState(() => capas.removeAt(e.key)),
                          ),
                        ),
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

                      // ================= OVERALL ASSESSMENT
                      sectionCard('Overall Assessment', [
                        DropdownButtonFormField<String>(
                          initialValue: overallAssessment,
                          validator: (v) => dropdownValidator(v, 'Assessment'),
                          decoration: const InputDecoration(labelText: 'Assessment'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Satisfactory',
                              child: Text('Satisfactory'),
                            ),
                            DropdownMenuItem(
                              value: 'Needs Improvement',
                              child: Text('Needs Improvement'),
                            ),
                            DropdownMenuItem(
                              value: 'Critical',
                              child: Text('Critical'),
                            ),
                          ],
                          onChanged: (v) => setState(() => overallAssessment = v!),
                        ),
                      ]),

                      // ================= SIGN OFF
                      sectionCard('Sign-Off', [
                        AppTextFieldWidget(
                          labelText: 'Compliance Officer Name',
                          labelTextStyle: labelStyle,
                          textFieldController: officerSignNameCtrl,
                          validator: (v) => requiredValidator(v, 'Officer Name'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Compliance Officer Signature',
                          labelTextStyle: labelStyle,
                          textFieldController: officerSignCtrl,
                          validator: (v) => requiredValidator(v, 'Officer Signature'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Client Representative Name',
                          labelTextStyle: labelStyle,
                          textFieldController: clientRepNameCtrl,
                          validator: (v) => requiredValidator(v, 'Client Name'),
                        ),
                        AppTextFieldWidget(
                          labelText: 'Client Representative Signature',
                          labelTextStyle: labelStyle,
                          textFieldController: clientRepSignCtrl,
                          validator: (v) => requiredValidator(v, 'Client Signature'),
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
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;

                          if (!isScopeValid()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select at least one Scope of Review')),
                            );
                            return;
                          }

                          if (!areTablesValid()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please complete all table rows')),
                            );
                            return;
                          }
                          if ((selectedCustomer?.customerId??'').isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a company first'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }else if ((consultantUserModel?.userId??'').isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login first'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          if(widget.visitorSummaryModel!=null){
                            context.read<VisitorSummaryCubit>().updateVisitorSummary(docId: widget.visitorSummaryModel?.id??'', payload:  _buildPayload(),selectedCustomer: selectedCustomer,consultantUserModel: consultantUserModel);
                          }else {
                            context.read<VisitorSummaryCubit>().createVisitorSummary(payload: _buildPayload(),selectedCustomer: selectedCustomer,consultantUserModel: consultantUserModel);
                          }
                        },
                        child: const Text('Submit'),
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
    return scopeReview.values.any((v) => v == 'Yes');
  }

  bool areTablesValid() {
    for (final o in observations) {
      if (o.values.any((c) => c.text.trim().isEmpty)) return false;
    }
    for (final n in nonCompliances) {
      if (n.values.any((c) => c.text.trim().isEmpty)) return false;
    }
    for (final c in capas) {
      if (c.values.any((x) => x.text.trim().isEmpty)) return false;
    }
    return true;
  }
}
