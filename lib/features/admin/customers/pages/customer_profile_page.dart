import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/core/access/access_control.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_profile_edit_page.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_hierarchy_graph.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class CustomerProfilePage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerProfilePage({super.key, required this.customer});

  @override
  State<CustomerProfilePage> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerProfilePage> {
  late CustomerModel customer;

  @override
  void initState() {
    super.initState();
    customer = widget.customer;
  }

  Future<void> _openEditPage() async {
    final updatedCustomer = await GoRouter.of(
      context,
    ).push<CustomerModel>(AppRoutes.customerEdit, extra: widget.customer);

    if (updatedCustomer != null) {
      setState(() {
        customer = updatedCustomer; // Auto reflects changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => GoRouter.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),

        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.whiteTextColor),
        ),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
  if (AccessControl.canEditCustomer(customer))
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.white),
      onPressed: _openEditPage,
    ),
],

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(appHorizontalPadding15),
        child: Column(
          children: [
            _readOnly('Company Name', customer.companyName),
            _readOnly('Email', customer.email),
            _readOnly('Phone', customer.phoneNumber),
            _readOnly('Certificate Standard', customer.certificateStandard),
            _readOnly('Employees', customer.numberOfEmployees),
            _readOnly('Locations', customer.numberOfLocations),
            _readOnly('Address', customer.address),

            verticalSpace20,

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Department Hierarchy",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            verticalSpaceSmall,

            /// ✅ USE UPDATED CUSTOMER
            CustomerHierarchyCustom(customer: customer),
          ],
        ),
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return AppTextFieldWidget(
      labelText: label,
      textFieldController: TextEditingController(text: value),
      readOnly: true,
      isEnabled: false,
      margin: const EdgeInsets.only(bottom: 10),
    );
  }
}
