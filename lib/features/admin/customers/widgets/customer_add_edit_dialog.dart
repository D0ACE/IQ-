import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';

class CustomerAddEditDialog extends StatefulWidget {
  final CustomerModel? customer;
  const CustomerAddEditDialog({super.key, this.customer});

  @override
  State<CustomerAddEditDialog> createState() => _CustomerAddEditDialogState();
}

class _CustomerAddEditDialogState extends State<CustomerAddEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Organization Core
  late TextEditingController companyNameCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;

  // Compliance Specifications
  late TextEditingController certificateCtrl;
  late TextEditingController locationsCtrl;
  late TextEditingController employeesCtrl;
  late TextEditingController companyFunctionCtrl;
  late TextEditingController legitDocumentUrlCtrl;

  // 🔹 Low level department
  late TextEditingController lowNameCtrl;
  late TextEditingController lowEmailCtrl;
  late TextEditingController lowMobileCtrl;

  // 🔹 Medium level department
  late TextEditingController mediumNameCtrl;
  late TextEditingController mediumEmailCtrl;
  late TextEditingController mediumMobileCtrl;

  // 🔹 Top level department
  late TextEditingController topNameCtrl;
  late TextEditingController topEmailCtrl;
  late TextEditingController topMobileCtrl;

  String? selectedFileName;
  String? selectedConsultantId;

  @override
  void initState() {
    super.initState();
    context.read<ConsultantCubit>().fetchConsultants();
    final c = widget.customer;
    
    companyNameCtrl = TextEditingController(text: c?.companyName);
    addressCtrl = TextEditingController(text: c?.address);
    phoneCtrl = TextEditingController(text: c?.phoneNumber);
    emailCtrl = TextEditingController(text: c?.email);

    certificateCtrl = TextEditingController(text: c?.certificateStandard);
    locationsCtrl = TextEditingController(text: c?.numberOfLocations);
    employeesCtrl = TextEditingController(text: c?.numberOfEmployees);
    companyFunctionCtrl = TextEditingController(text: c?.companyFunction);
    legitDocumentUrlCtrl = TextEditingController(text: c?.legitDocumentUrl);

    lowNameCtrl = TextEditingController(text: c?.lowLevelName);
    lowEmailCtrl = TextEditingController(text: c?.lowLevelEmail);
    lowMobileCtrl = TextEditingController(text: c?.lowLevelMobile);

    mediumNameCtrl = TextEditingController(text: c?.mediumLevelName);
    mediumEmailCtrl = TextEditingController(text: c?.mediumLevelEmail);
    mediumMobileCtrl = TextEditingController(text: c?.mediumLevelMobile);

    topNameCtrl = TextEditingController(text: c?.topLevelName);
    topEmailCtrl = TextEditingController(text: c?.topLevelEmail);
    topMobileCtrl = TextEditingController(text: c?.topLevelMobile);
    
    selectedConsultantId = c?.consultantId;
  }

  @override
  void dispose() {
    companyNameCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    certificateCtrl.dispose();
    locationsCtrl.dispose();
    employeesCtrl.dispose();
    companyFunctionCtrl.dispose();
    legitDocumentUrlCtrl.dispose();

    lowNameCtrl.dispose();
    lowEmailCtrl.dispose();
    lowMobileCtrl.dispose();

    mediumNameCtrl.dispose();
    mediumEmailCtrl.dispose();
    mediumMobileCtrl.dispose();

    topNameCtrl.dispose();
    topEmailCtrl.dispose();
    topMobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        legitDocumentUrlCtrl.text = selectedFileName!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.customer != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? "Update Enterprise Identity" : "Register New Customer",
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
          ),
          const SizedBox(height: 4),
          Text(
            isEdit ? "Modifying profile for ${widget.customer!.companyName}" : "Initiating a new organization onboarding",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _sectionHeader("ORGANIZATION CORE"),
                _buildModernField("Company Name", companyNameName: companyNameCtrl, icon: Icons.business_rounded, isRequired: true),
                _buildModernField("Headquarters Address", companyNameName: addressCtrl, icon: Icons.location_on_rounded, isRequired: true),
                _buildModernField("Primary Contact", companyNameName: phoneCtrl, icon: Icons.phone_android_rounded, isRequired: true, keyboardType: TextInputType.phone),
                _buildModernField("Corporate Email", companyNameName: emailCtrl, icon: Icons.alternate_email_rounded, isRequired: true, isEnabled: !isEdit, validator: AppValidation.checkEmailValidation, keyboardType: TextInputType.emailAddress),
                
                const SizedBox(height: 20),
                _sectionHeader("COMPLIANCE & DOCUMENTS"),
                _buildModernField("Standard of Certificate", companyNameName: certificateCtrl, icon: Icons.verified_rounded),
                Row(
                  children: [
                    Expanded(child: _buildModernField("Locations", companyNameName: locationsCtrl, icon: Icons.map_rounded, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModernField("Workforce", companyNameName: employeesCtrl, icon: Icons.groups_rounded, keyboardType: TextInputType.number)),
                  ],
                ),
                _buildFileUploadField(),
                _buildModernField("Operational Function", companyNameName: companyFunctionCtrl, icon: Icons.settings_suggest_rounded),

                const SizedBox(height: 20),
                _departmentSection("LEVEL 01: OPERATIONAL CONTROL", lowNameCtrl, lowEmailCtrl, lowMobileCtrl),
                _departmentSection("LEVEL 02: TACTICAL MANAGEMENT", mediumNameCtrl, mediumEmailCtrl, mediumMobileCtrl),
                _departmentSection("LEVEL 03: STRATEGIC OVERSIGHT", topNameCtrl, topEmailCtrl, topMobileCtrl),

                const SizedBox(height: 20),
                _sectionHeader("SYSTEM ASSIGNMENT"),
                BlocBuilder<ConsultantCubit, ConsultantState>(
                  builder: (context, state) {
                    if (state is ConsultantLoading) {
                      return const LinearProgressIndicator();
                    }

                    if (state is ConsultantLoaded) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedConsultantId,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: AppColors.titleText, fontWeight: FontWeight.bold, fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Assign Lead Consultant',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                          ),
                          items: state.consultants.map((consultant) {
                            return DropdownMenuItem<String>(
                              value: consultant.id,
                              child: Text(consultant.userName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedConsultantId = value;
                            });
                          },
                          validator: (v) => v == null ? "Required" : null,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("CANCEL", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _onSave,
          child: Text(isEdit ? "UPDATE ACCOUNT" : "REGISTER CUSTOMER", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2),
      ),
    );
  }

  Widget _buildModernField(String hint, {required TextEditingController companyNameName, required IconData icon, bool isRequired = false, bool isEnabled = true, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: AppTextFieldWidget(
          hintText: hint,
          textFieldController: companyNameName,
          isRequired: isRequired,
          isEnabled: isEnabled,
          validator: validator,
          keyboardType: keyboardType,
          prefixIconWidget: Icon(icon, color: AppColors.primary, size: 20),
          textStyle: const TextStyle(color: AppColors.titleText, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15), 
                borderSide: const BorderSide(color: AppColors.primary, width: 2)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _pickDocument,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFileName ?? (widget.customer?.legitDocumentUrl.isNotEmpty == true ? "Document Attached" : "Legal Documentation"),
                      style: TextStyle(
                        color: selectedFileName != null || widget.customer?.legitDocumentUrl.isNotEmpty == true ? Colors.green.shade700 : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text("PDF, DOC, or Image format", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _departmentSection(String title, TextEditingController name, TextEditingController email, TextEditingController mobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            _buildModernField("Authority Name", companyNameName: name, icon: Icons.person_rounded, isRequired: true),
            _buildModernField("Direct Email", companyNameName: email, icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, validator: AppValidation.checkEmailValidation),
            _buildModernField("Mobile Connection", companyNameName: mobile, icon: Icons.phone_rounded, keyboardType: TextInputType.phone, validator: AppValidation.phoneNumberValidator),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (selectedConsultantId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please assign a consultant")),
        );
        return;
      }

      final cubit = context.read<CustomerListCubit>();
      final isNew = widget.customer == null;
      
      final data = CustomerModel(
        customerId: widget.customer?.customerId ?? '',
        companyName: companyNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        password: isNew ? Utility.autoGeneratePassword() : widget.customer!.password,
        certificateStandard: certificateCtrl.text.trim(),
        numberOfLocations: locationsCtrl.text.trim(),
        numberOfEmployees: employeesCtrl.text.trim(),
        companyFunction: companyFunctionCtrl.text.trim(),
        legitDocumentUrl: legitDocumentUrlCtrl.text.trim(),
        isProfileApproved: isNew ? true : widget.customer!.isProfileApproved,
        fcmToken: widget.customer?.fcmToken ?? "",
        roleId: AppConst.customerRole,
        lowLevelName: lowNameCtrl.text.trim(),
        lowLevelEmail: lowEmailCtrl.text.trim(),
        lowLevelMobile: lowMobileCtrl.text.trim(),
        mediumLevelName: mediumNameCtrl.text.trim(),
        mediumLevelEmail: mediumEmailCtrl.text.trim(),
        mediumLevelMobile: mediumMobileCtrl.text.trim(),
        topLevelName: topNameCtrl.text.trim(),
        topLevelEmail: topEmailCtrl.text.trim(),
        topLevelMobile: topMobileCtrl.text.trim(),
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        consultantId: selectedConsultantId,
        nextVisitDate: widget.customer?.nextVisitDate,
      );

      if (isNew) {
        cubit.createCustomer(data);
      } else {
        cubit.updateCustomer(data);
      }
      Navigator.pop(context);
    }
  }
}
