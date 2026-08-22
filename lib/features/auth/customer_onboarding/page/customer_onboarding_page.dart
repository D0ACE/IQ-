import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/common/themes/components/background.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/customer_onboarding/onboarding_mode.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/cubit/customer/state/customer_state.dart';

class CustomerOnboardingPage extends StatefulWidget {
  final OnboardingMode mode;
  final CustomerModel? customer;
  const CustomerOnboardingPage({super.key, required this.mode, this.customer});

  @override
  State<CustomerOnboardingPage> createState() => _CustomerOnboardingPageState();
}

class _CustomerOnboardingPageState extends State<CustomerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  final addressController = TextEditingController();
  final companyNameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final standardOfCertificateController = TextEditingController();
  final numberOfLocationsController = TextEditingController();
  final numberOfEmployeesController = TextEditingController();
  final lDCController = TextEditingController();
  final fOCController = TextEditingController();
  // 🔹 Low level department
  final lowNameController = TextEditingController();
  final lowEmailController = TextEditingController();
  final lowMobileController = TextEditingController();

  // 🔹 Medium level department
  final mediumNameController = TextEditingController();
  final mediumEmailController = TextEditingController();
  final mediumMobileController = TextEditingController();

  // 🔹 Top level department
  final topNameController = TextEditingController();
  final topEmailController = TextEditingController();
  final topMobileController = TextEditingController();

  String? selectedFileName;
  String? selectedConsultantId;

  @override
  void initState() {
    super.initState();

    if (widget.mode == OnboardingMode.approve && widget.customer != null) {
      _fillCustomerData(widget.customer!);
      selectedConsultantId = widget.customer!.consultantId; // 🚀 Initialize
    }
    
    context.read<ConsultantCubit>().fetchConsultants();
  }

  void _fillCustomerData(CustomerModel customer) {
    companyNameController.text = customer.companyName;
    addressController.text = customer.address;
    contactController.text = customer.phoneNumber;
    emailController.text = customer.email;

    standardOfCertificateController.text = customer.certificateStandard;
    numberOfLocationsController.text = customer.numberOfLocations;
    numberOfEmployeesController.text = customer.numberOfEmployees;
    fOCController.text = customer.companyFunction;
    lDCController.text = customer.legitDocumentUrl;

    // LOW LEVEL
    lowNameController.text = customer.lowLevelName;
    lowEmailController.text = customer.lowLevelEmail;
    lowMobileController.text = customer.lowLevelMobile;

    // MEDIUM LEVEL
    mediumNameController.text = customer.mediumLevelName;
    mediumEmailController.text = customer.mediumLevelEmail;
    mediumMobileController.text = customer.mediumLevelMobile;

    // TOP LEVEL
    topNameController.text = customer.topLevelName;
    topEmailController.text = customer.topLevelEmail;
    topMobileController.text = customer.topLevelMobile;
  }

  @override
  void dispose() {
    addressController.dispose();
    companyNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    standardOfCertificateController.dispose();
    numberOfLocationsController.dispose();
    numberOfEmployeesController.dispose();
    lDCController.dispose();
    fOCController.dispose();

    lowNameController.dispose();
    lowEmailController.dispose();
    lowMobileController.dispose();

    mediumNameController.dispose();
    mediumEmailController.dispose();
    mediumMobileController.dispose();

    topNameController.dispose();
    topEmailController.dispose();
    topMobileController.dispose();
    super.dispose();
  }

  Future<void> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        lDCController.text = selectedFileName!;
      });
    }
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      final data = CustomerModel(
        customerId: '', // Firestore will generate
        companyName: companyNameController.text.trim(),
        address: addressController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: contactController.text.trim(),
        password: "",
        certificateStandard: standardOfCertificateController.text.trim(),
        numberOfLocations: numberOfLocationsController.text.trim(),
        numberOfEmployees: numberOfEmployeesController.text.trim(),
        companyFunction: fOCController.text.trim(),
        legitDocumentUrl: lDCController.text.trim(),
        isProfileApproved: false,
        fcmToken: "",
        roleId: "3",
        // 🔽 LOW LEVEL DEPARTMENT
        lowLevelName: lowNameController.text.trim(),
        lowLevelEmail: lowEmailController.text.trim(),
        lowLevelMobile: lowMobileController.text.trim(),

        // 🔶 MEDIUM LEVEL DEPARTMENT
        mediumLevelName: mediumNameController.text.trim(),
        mediumLevelEmail: mediumEmailController.text.trim(),
        mediumLevelMobile: mediumMobileController.text.trim(),

        // 🔺 TOP LEVEL DEPARTMENT
        topLevelName: topNameController.text.trim(),
        topLevelEmail: topEmailController.text.trim(),
        topLevelMobile: topMobileController.text.trim(),
        createdAt: DateTime.now(), // placeholder
      );

      context.read<CustomerCubit>().createCustomer(data);
    }
  }

  void approveCustomer() async {
    if (widget.customer == null) return;

    if (selectedConsultantId == null || selectedConsultantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select consultant first.")),
      );
      return;
    }

    await context.read<CustomerListCubit>().approveCustomer(
          customerId: widget.customer!.customerId,
          companyName: widget.customer!.companyName,
          customerEmail: widget.customer!.email,
          consultantId: selectedConsultantId!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Background(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<CustomerCubit, CustomerState>(
                      listener: (context, state) {
                        if (state is CustomerSuccess) {
                          context.read<CustomerCubit>().fetchPendingCustomers();
                          showAccountCreatedDialog();
                        }
                        if (state is CustomerError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                    ),
                    BlocListener<CustomerListCubit, CustomerListState>(
                      listener: (context, state) {
                        if (state is CustomerListOperationSuccess) {
                          // Refresh pending list for the previous screen
                          context.read<CustomerCubit>().fetchPendingCustomers();
                          showAccountCreatedDialog();
                        }
                        if (state is CustomerListError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                    ),
                  ],
                  child: BlocBuilder<CustomerCubit, CustomerState>(
                    builder: (context, state) {
                      final isCustLoading = state is CustomerLoading;
                      return BlocBuilder<CustomerListCubit, CustomerListState>(
                        builder: (context, listState) {
                          final isListLoading = listState is CustomerListLoading;
                          return formWidget(isCustLoading || isListLoading);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAccountCreatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: Text(
          widget.mode == OnboardingMode.create
              ? "Account created successfully. Await admin approval."
              : "Customer approved successfully.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              GoRouter.of(context).pop(); // close dialog

              if (widget.mode == OnboardingMode.create) {
                GoRouter.of(context).pop(); // go back to login
              } else {
                GoRouter.of(context).pop(); // go back from details/onboarding
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget formWidget(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextFieldWidget(
            keyboardType: TextInputType.name,
            hintText: "Company Name",
            textFieldController: companyNameController,
            onTap: () {},
            prefixIconWidget: const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(
                Icons.person,
                color: AppColors.kPrimaryColor,
                size: 23,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
            disableFocusBorder: true,
            isRequired: true,
            decoration: const InputDecoration(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Address",
              textFieldController: addressController,
              onTap: () {},
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              isRequired: true,
              decoration: const InputDecoration(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Contact",
              textFieldController: contactController,
              onTap: () {},
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.phone,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              isRequired: true,
              decoration: const InputDecoration(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Email",
              validator: AppValidation.checkEmailValidation,
              textFieldController: emailController,
              onTap: () {},
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.email,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              isRequired: true,
              decoration: const InputDecoration(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Standard Of Certificate",
              textFieldController: standardOfCertificateController,
              onTap: () {},
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.lan_rounded,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              isRequired: true,
              decoration: const InputDecoration(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Number of locations",
              validator: AppValidation.numberOfLocationValidator,
              keyboardType: TextInputType.number,
              textFieldController: numberOfLocationsController,
              onTap: () {},
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              decoration: const InputDecoration(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Number of employees",
              textFieldController: numberOfEmployeesController,
              onTap: () {},
              validator: AppValidation.numberOfEmployeesValidator,
              keyboardType: TextInputType.number,
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.group,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              decoration: const InputDecoration(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextFieldWidget(
                  hintText: "Legit document of the company",
                  textFieldController: lDCController,
                  readOnly: true,
                  onTap: pickDocument,
                  prefixIconWidget: const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.file_copy,
                      color: AppColors.kPrimaryColor,
                      size: 23,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
                  disableFocusBorder: true,
                  isRequired: true,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: pickDocument,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Document"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Selected: $selectedFileName",
                      style: const TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: AppTextFieldWidget(
              hintText: "Function of the company",
              textFieldController: fOCController,
              onTap: () {},
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(
                  Icons.functions,
                  color: AppColors.kPrimaryColor,
                  size: 23,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
              disableFocusBorder: true,
              isRequired: true,
              decoration: const InputDecoration(),
            ),
          ),
          departmentSection(
            title: "Low Level Department Details",
            nameController: lowNameController,
            emailController: lowEmailController,
            mobileController: lowMobileController,
          ),
          departmentSection(
            title: "Medium Level Department Details",
            nameController: mediumNameController,
            emailController: mediumEmailController,
            mobileController: mediumMobileController,
          ),
          departmentSection(
            title: "Top Level Department Details",
            nameController: topNameController,
            emailController: topEmailController,
            mobileController: topMobileController,
          ),

          if (widget.mode == OnboardingMode.approve) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Assign Consultant *",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            BlocBuilder<ConsultantCubit, ConsultantState>(
              builder: (context, state) {
                if (state is ConsultantLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ConsultantLoaded) {
                  return DropdownButtonFormField<String>(
                    value: selectedConsultantId, // 🚀 Show currently selected
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    hint: const Text('Select Consultant'),
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
                    validator: (v) =>
                        v == null ? "Please select a consultant" : null,
                  );
                }

                if (state is ConsultantError) {
                  return Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  );
                }

                return const SizedBox();
              },
            ),
            const SizedBox(height: 20),
          ],
          
          GradientButton(
            text: widget.mode == OnboardingMode.create ? "Create Account" : "Approve",
            isLoading: isLoading,
            onPressed: isLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    if (widget.mode == OnboardingMode.create) {
                      submit();
                    } else {
                      approveCustomer();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget departmentSection({
    required String title,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController mobileController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            AppTextFieldWidget(
              hintText: "Name",
              textFieldController: nameController,
              isRequired: true,
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.person, color: AppColors.kPrimaryColor),
              ),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 10),
            AppTextFieldWidget(
              hintText: "Email",
              keyboardType: TextInputType.emailAddress,
              validator: AppValidation.checkEmailValidation,
              textFieldController: emailController,
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.email, color: AppColors.kPrimaryColor),
              ),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 10),
            AppTextFieldWidget(
              hintText: "Mobile Number",
              keyboardType: TextInputType.phone,
              textFieldController: mobileController,
              validator: AppValidation.phoneNumberValidator,
              prefixIconWidget: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.phone, color: AppColors.kPrimaryColor),
              ),
              decoration: const InputDecoration(),
            ),
          ],
        ),
      ),
    );
  }
}
