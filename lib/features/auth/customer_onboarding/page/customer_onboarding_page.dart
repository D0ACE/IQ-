import 'dart:math';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
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

class _CustomerOnboardingPageState extends State<CustomerOnboardingPage> with TickerProviderStateMixin {
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

  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    if (widget.mode == OnboardingMode.approve && widget.customer != null) {
      _fillCustomerData(widget.customer!);
      selectedConsultantId = widget.customer!.consultantId;
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
    _floatController.dispose();
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🚀 Animated Vibrant Mesh Background
          _buildAnimatedBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
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
                                SnackBar(
                                  backgroundColor: AppColors.kPrimaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(state.message),
                                ),
                              );
                            }
                          },
                        ),
                        BlocListener<CustomerListCubit, CustomerListState>(
                          listener: (context, state) {
                            if (state is CustomerListOperationSuccess) {
                              context.read<CustomerCubit>().fetchPendingCustomers();
                              showAccountCreatedDialog();
                            }
                            if (state is CustomerListError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.kPrimaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(state.message),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 30),
                          _buildGlassCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // 🎨 Dynamically shifting hues for background consistency
        final double hueBase = _floatController.value * 360;
        final Color color1 = HSLColor.fromAHSL(1.0, hueBase % 360, 0.65, 0.94).toColor();
        final Color color2 = HSLColor.fromAHSL(1.0, (hueBase + 60) % 360, 0.7, 0.97).toColor();
        final Color color3 = HSLColor.fromAHSL(1.0, (hueBase + 120) % 360, 0.65, 0.94).toColor();

        return Stack(
          children: [
            // 🌈 Animated Base Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color1, color2, color3],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Orb 1: Indigo (Moving)
            Positioned(
              top: -100 + (100 * sin(_floatController.value * 2 * pi)),
              right: -50 + (50 * cos(_floatController.value * 2 * pi)),
              child: _buildBlurOrb(600, const Color(0xFF6366F1).withValues(alpha: 0.12)),
            ),
            
            // Orb 2: Teal (Moving)
            Positioned(
              bottom: -150 + (120 * cos(_floatController.value * 2 * pi)),
              left: -100 + (80 * sin(_floatController.value * 2 * pi)),
              child: _buildBlurOrb(550, const Color(0xFF14B8A6).withValues(alpha: 0.12)),
            ),

            // ❄️ Subtle Frost Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.white.withValues(alpha: 0.02)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "O N B O A R D I N G",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 40, height: 3, color: AppColors.kPrimaryColor),
        const SizedBox(height: 20),
        Text(
          widget.mode == OnboardingMode.create ? "Create Operator Identity" : "Authorize Enterprise",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85), // 🛡️ Higher opacity for readability
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
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
    );
  }

  void showAccountCreatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("System Notification", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          widget.mode == OnboardingMode.create
              ? "Onboarding request transmitted successfully. Awaiting terminal authorization."
              : "Enterprise identity verified and approved.",
          style: const TextStyle(fontWeight: FontWeight.w500),
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
            child: const Text("ACKNOWLEDGE", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget formWidget(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader("ORGANIZATION CORE"),
          _buildModernField(
            hintText: "Company Name",
            controller: companyNameController,
            icon: Icons.business_rounded,
            isRequired: true,
          ),
          _buildModernField(
            hintText: "Address",
            controller: addressController,
            icon: Icons.location_on_rounded,
            isRequired: true,
          ),
          _buildModernField(
            hintText: "Contact",
            controller: contactController,
            icon: Icons.phone_android_rounded,
            isRequired: true,
            keyboardType: TextInputType.phone,
          ),
          _buildModernField(
            hintText: "Email",
            controller: emailController,
            icon: Icons.alternate_email_rounded,
            isRequired: true,
            validator: AppValidation.checkEmailValidation,
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 30),
          _sectionHeader("COMPLIANCE SPECIFICATIONS"),
          _buildModernField(
            hintText: "Standard Of Certificate",
            controller: standardOfCertificateController,
            icon: Icons.verified_rounded,
            isRequired: true,
          ),
          _buildModernField(
            hintText: "Number of locations",
            controller: numberOfLocationsController,
            icon: Icons.map_rounded,
            keyboardType: TextInputType.number,
            validator: AppValidation.numberOfLocationValidator,
          ),
          _buildModernField(
            hintText: "Number of employees",
            controller: numberOfEmployeesController,
            icon: Icons.groups_rounded,
            keyboardType: TextInputType.number,
            validator: AppValidation.numberOfEmployeesValidator,
          ),
          
          const SizedBox(height: 30),
          _sectionHeader("LEGAL DOCUMENTATION"),
          _buildFileUploadField(),
          
          _buildModernField(
            hintText: "Function of the company",
            controller: fOCController,
            icon: Icons.settings_suggest_rounded,
            isRequired: true,
          ),

          const SizedBox(height: 30),
          departmentSection(
            title: "LEVEL 01: OPERATIONAL CONTROL",
            nameController: lowNameController,
            emailController: lowEmailController,
            mobileController: lowMobileController,
          ),
          departmentSection(
            title: "LEVEL 02: TACTICAL MANAGEMENT",
            nameController: mediumNameController,
            emailController: mediumEmailController,
            mobileController: mediumMobileController,
          ),
          departmentSection(
            title: "LEVEL 03: STRATEGIC OVERSIGHT",
            nameController: topNameController,
            emailController: topEmailController,
            mobileController: topMobileController,
          ),

          if (widget.mode == OnboardingMode.approve) ...[
            const SizedBox(height: 30),
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
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedConsultantId,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Assign Designated Consultant',
                        hintStyle: TextStyle(color: Colors.grey),
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
                      validator: (v) => v == null ? "Required: Assign Consultant" : null,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
          
          const SizedBox(height: 50),
          Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: GradientButton(
              text: widget.mode == OnboardingMode.create ? "INITIATE ONBOARDING" : "AUTHORIZE ACCESS",
              isLoading: isLoading,
              radiusSize: 20,
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
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: const Text(
              "ABORT MISSION",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildModernField({
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // 🛡️ Solid light grey for visibility
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: AppTextFieldWidget(
          keyboardType: keyboardType,
          hintText: hintText,
          textFieldController: controller,
          isRequired: isRequired,
          validator: validator,
          prefixIconWidget: Icon(icon, color: AppColors.kPrimaryColor, size: 20),
          textStyle: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 2)
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
        onTap: pickDocument,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: AppColors.kPrimaryColor, size: 32),
              const SizedBox(height: 12),
              Text(
                selectedFileName ?? "Legit document of the company",
                style: TextStyle(
                  color: selectedFileName != null ? Colors.green : AppColors.kPrimaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                "PDF, DOC, or Image allowed",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, // 🛡️ Solid background for visibility
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
            const SizedBox(height: 20),
            _buildModernField(hintText: "Name", controller: nameController, icon: Icons.person_rounded, isRequired: true),
            _buildModernField(hintText: "Email", controller: emailController, icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, validator: AppValidation.checkEmailValidation),
            _buildModernField(hintText: "Mobile Number", controller: mobileController, icon: Icons.phone_rounded, keyboardType: TextInputType.phone, validator: AppValidation.phoneNumberValidator),
          ],
        ),
      ),
    );
  }
}
