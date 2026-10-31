import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:go_router/go_router.dart';

class CustomerProfileEditPage extends StatefulWidget {
  final CustomerModel customer;
  const CustomerProfileEditPage({super.key, required this.customer});

  @override
  State<CustomerProfileEditPage> createState() =>
      _CustomerProfileEditPageState();
}

class _CustomerProfileEditPageState extends State<CustomerProfileEditPage> {
  late TextEditingController companyCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController certificateCtrl;
  late TextEditingController locationsCtrl;
  late TextEditingController employeesCtrl;
  late TextEditingController companyFunctionCtrl;

  // Department controllers
  late TextEditingController topNameCtrl;
  late TextEditingController topEmailCtrl;
  late TextEditingController topMobileCtrl;

  late TextEditingController mediumNameCtrl;
  late TextEditingController mediumEmailCtrl;
  late TextEditingController mediumMobileCtrl;

  late TextEditingController lowNameCtrl;
  late TextEditingController lowEmailCtrl;
  late TextEditingController lowMobileCtrl;

  Uint8List? selectedFileBytes;
  String? selectedFileName;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    companyCtrl = TextEditingController(text: c.companyName);
    phoneCtrl = TextEditingController(text: AppValidation.formatPhoneForEdit(c.phoneNumber));
    emailCtrl = TextEditingController(text: c.email);
    addressCtrl = TextEditingController(text: c.address);
    certificateCtrl = TextEditingController(text: c.certificateStandard);
    locationsCtrl = TextEditingController(text: c.numberOfLocations);
    employeesCtrl = TextEditingController(text: c.numberOfEmployees);
    companyFunctionCtrl = TextEditingController(text: c.companyFunction);

    topNameCtrl = TextEditingController(text: c.topLevelName);
    topEmailCtrl = TextEditingController(text: c.topLevelEmail);
    topMobileCtrl = TextEditingController(text: AppValidation.formatPhoneForEdit(c.topLevelMobile));

    mediumNameCtrl = TextEditingController(text: c.mediumLevelName);
    mediumEmailCtrl = TextEditingController(text: c.mediumLevelEmail);
    mediumMobileCtrl = TextEditingController(text: AppValidation.formatPhoneForEdit(c.mediumLevelMobile));

    lowNameCtrl = TextEditingController(text: c.lowLevelName);
    lowEmailCtrl = TextEditingController(text: c.lowLevelEmail);
    lowMobileCtrl = TextEditingController(text: AppValidation.formatPhoneForEdit(c.lowLevelMobile));
  }

  @override
  void dispose() {
    companyCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    certificateCtrl.dispose();
    locationsCtrl.dispose();
    employeesCtrl.dispose();
    companyFunctionCtrl.dispose();

    topNameCtrl.dispose();
    topEmailCtrl.dispose();
    topMobileCtrl.dispose();

    mediumNameCtrl.dispose();
    mediumEmailCtrl.dispose();
    mediumMobileCtrl.dispose();

    lowNameCtrl.dispose();
    lowEmailCtrl.dispose();
    lowMobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedFileBytes = result.files.single.bytes;
        selectedFileName = result.files.single.name;
      });
    }
  }

  Widget _buildFileUploadField() {
    final bool hasExistingDoc = widget.customer.legitDocumentUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _pickDocument,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: Colors.blue, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFileName ?? (hasExistingDoc ? "Legal Document Attached" : "Legal Documentation"),
                      style: TextStyle(
                        color: selectedFileName != null || hasExistingDoc ? Colors.green.shade700 : Colors.blue,
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

  Future<void> _updateProfile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String legitUrl = widget.customer.legitDocumentUrl;
    if (selectedFileBytes != null && selectedFileName != null) {
      try {
        final supabasePath = 'legal_docs/${DateTime.now().millisecondsSinceEpoch}_$selectedFileName';
        await Supabase.instance.client.storage.from(SupabaseConfig.bucketName).uploadBinary(
          supabasePath,
          selectedFileBytes!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        legitUrl = Supabase.instance.client.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);
      } catch (e) {
        debugPrint("Error uploading legal doc: $e");
      }
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final updatedCustomer = widget.customer.copyWith(
      companyName: companyCtrl.text,
      phoneNumber: phoneCtrl.text,
      address: addressCtrl.text,
      certificateStandard: certificateCtrl.text,
      numberOfLocations: locationsCtrl.text,
      numberOfEmployees: employeesCtrl.text,
      companyFunction: companyFunctionCtrl.text,
      topLevelName: topNameCtrl.text,
      topLevelEmail: topEmailCtrl.text,
      topLevelMobile: topMobileCtrl.text,
      mediumLevelName: mediumNameCtrl.text,
      mediumLevelEmail: mediumEmailCtrl.text,
      mediumLevelMobile: mediumMobileCtrl.text,
      lowLevelName: lowNameCtrl.text,
      lowLevelEmail: lowEmailCtrl.text,
      lowLevelMobile: lowMobileCtrl.text,
      legitDocumentUrl: legitUrl,
    );

    // Save to Hive
    await getIt<HiveService>().saveCustomer(updatedCustomer);
    try {
      await FirebaseFirestore.instance.collection('customers').doc(updatedCustomer.customerId).set(updatedCustomer.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating customer in Firestore: $e");
    }

    if (!mounted) return;
    context.pop(updatedCustomer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextFieldWidget(labelText: "Company Name", textFieldController: companyCtrl),
            AppTextFieldWidget(labelText: "Email", textFieldController: emailCtrl, readOnly: true, isEnabled: false),
            AppTextFieldWidget(labelText: "Phone", textFieldController: phoneCtrl, prefixText: "+91 ", keyboardType: TextInputType.number, inputFormatters: AppValidation.phoneNumberFormatters(), validator: AppValidation.phoneNumberValidator),
            AppTextFieldWidget(labelText: "Address", textFieldController: addressCtrl),
            AppTextFieldWidget(labelText: "Certificate Standard", textFieldController: certificateCtrl),
            AppTextFieldWidget(labelText: "Number of Locations", textFieldController: locationsCtrl),
            AppTextFieldWidget(labelText: "Number of Employees", textFieldController: employeesCtrl),
            AppTextFieldWidget(labelText: "Company Function", textFieldController: companyFunctionCtrl),
            const SizedBox(height: 12),
            _buildFileUploadField(),

            const SizedBox(height: 20),
            const Text("Top Level Department", style: TextStyle(fontWeight: FontWeight.bold)),
            AppTextFieldWidget(labelText: "Name", textFieldController: topNameCtrl),
            AppTextFieldWidget(labelText: "Email", textFieldController: topEmailCtrl),
            AppTextFieldWidget(labelText: "Mobile", textFieldController: topMobileCtrl, prefixText: "+91 ", keyboardType: TextInputType.number, inputFormatters: AppValidation.phoneNumberFormatters(), validator: AppValidation.phoneNumberValidator),

            const SizedBox(height: 10),
            const Text("Medium Level Department", style: TextStyle(fontWeight: FontWeight.bold)),
            AppTextFieldWidget(labelText: "Name", textFieldController: mediumNameCtrl),
            AppTextFieldWidget(labelText: "Email", textFieldController: mediumEmailCtrl),
            AppTextFieldWidget(labelText: "Mobile", textFieldController: mediumMobileCtrl, prefixText: "+91 ", keyboardType: TextInputType.number, inputFormatters: AppValidation.phoneNumberFormatters(), validator: AppValidation.phoneNumberValidator),

            const SizedBox(height: 10),
            const Text("Low Level Department", style: TextStyle(fontWeight: FontWeight.bold)),
            AppTextFieldWidget(labelText: "Name", textFieldController: lowNameCtrl),
            AppTextFieldWidget(labelText: "Email", textFieldController: lowEmailCtrl),
            AppTextFieldWidget(labelText: "Mobile", textFieldController: lowMobileCtrl, prefixText: "+91 ", keyboardType: TextInputType.number, inputFormatters: AppValidation.phoneNumberFormatters(), validator: AppValidation.phoneNumberValidator),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Update"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
