import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    companyCtrl = TextEditingController(text: widget.customer.companyName);
    phoneCtrl = TextEditingController(text: widget.customer.phoneNumber);
    emailCtrl = TextEditingController(text: widget.customer.email);
    addressCtrl = TextEditingController(text: widget.customer.address);
    certificateCtrl = TextEditingController(
      text: widget.customer.certificateStandard,
    );
    locationsCtrl = TextEditingController(
      text: widget.customer.numberOfLocations,
    );
    employeesCtrl = TextEditingController(
      text: widget.customer.numberOfEmployees,
    );

    topNameCtrl = TextEditingController(text: widget.customer.topLevelName);
    topEmailCtrl = TextEditingController(text: widget.customer.topLevelEmail);
    topMobileCtrl = TextEditingController(text: widget.customer.topLevelMobile);

    mediumNameCtrl = TextEditingController(
      text: widget.customer.mediumLevelName,
    );
    mediumEmailCtrl = TextEditingController(
      text: widget.customer.mediumLevelEmail,
    );
    mediumMobileCtrl = TextEditingController(
      text: widget.customer.mediumLevelMobile,
    );

    lowNameCtrl = TextEditingController(text: widget.customer.lowLevelName);
    lowEmailCtrl = TextEditingController(text: widget.customer.lowLevelEmail);
    lowMobileCtrl = TextEditingController(text: widget.customer.lowLevelMobile);
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

  Future<void> _updateProfile() async {
    final updatedCustomer = widget.customer.copyWith(
      companyName: companyCtrl.text,
      phoneNumber: phoneCtrl.text,
      address: addressCtrl.text,
      certificateStandard: certificateCtrl.text,
      numberOfLocations: locationsCtrl.text,
      numberOfEmployees: employeesCtrl.text,
      topLevelName: topNameCtrl.text,
      topLevelEmail: topEmailCtrl.text,
      topLevelMobile: topMobileCtrl.text,
      mediumLevelName: mediumNameCtrl.text,
      mediumLevelEmail: mediumEmailCtrl.text,
      mediumLevelMobile: mediumMobileCtrl.text,
      lowLevelName: lowNameCtrl.text,
      lowLevelEmail: lowEmailCtrl.text,
      lowLevelMobile: lowMobileCtrl.text,
    );

    // Save to Hive
    await getIt<HiveService>().saveCustomer(updatedCustomer);

    if (!mounted) return;
    context.pop(updatedCustomer);
    // Return updated customer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextFieldWidget(
              labelText: "Company Name",
              textFieldController: companyCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Email",
              textFieldController: emailCtrl,
              readOnly: true,
              isEnabled: false,
            ),

            AppTextFieldWidget(
              labelText: "Phone",
              textFieldController: phoneCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Address",
              textFieldController: addressCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Certificate Standard",
              textFieldController: certificateCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Number of Locations",
              textFieldController: locationsCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Number of Employees",
              textFieldController: employeesCtrl,
            ),

            const SizedBox(height: 20),
            const Text(
              "Top Level Department",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            AppTextFieldWidget(
              labelText: "Name",
              textFieldController: topNameCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Email",
              textFieldController: topEmailCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Mobile",
              textFieldController: topMobileCtrl,
            ),

            const SizedBox(height: 10),
            const Text(
              "Medium Level Department",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            AppTextFieldWidget(
              labelText: "Name",
              textFieldController: mediumNameCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Email",
              textFieldController: mediumEmailCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Mobile",
              textFieldController: mediumMobileCtrl,
            ),

            const SizedBox(height: 10),
            const Text(
              "Low Level Department",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            AppTextFieldWidget(
              labelText: "Name",
              textFieldController: lowNameCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Email",
              textFieldController: lowEmailCtrl,
            ),
            AppTextFieldWidget(
              labelText: "Mobile",
              textFieldController: lowMobileCtrl,
            ),

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
