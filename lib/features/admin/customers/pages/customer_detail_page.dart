import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_hierarchy_graph.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:go_router/go_router.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerDetailPage> {
  String? selectedConsultantId;

  @override
  void initState() {
    super.initState();
    // 🚀 Initialize with currently assigned consultant
    selectedConsultantId = widget.customer.consultantId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerListCubit, CustomerListState>(
      listener: (context, state) {
        if (state is CustomerListOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          GoRouter.of(context).pop(); // 🚀 Pop back on success
        }
        if (state is CustomerListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          title: const Text('Customer Details'),
          backgroundColor: AppColors.primary,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(appHorizontalPadding15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _readOnly('Company Name', widget.customer.companyName),
                    _readOnly('Email', widget.customer.email),
                    _readOnly('Phone', widget.customer.phoneNumber),
                    _readOnly('Certificate Standard', widget.customer.certificateStandard),
                    _readOnly('Employees', widget.customer.numberOfEmployees),
                    _readOnly('Locations', widget.customer.numberOfLocations),
                    _readOnly('Address', widget.customer.address),

                    verticalSpace20,

                    /// ✅ CONSULTANT DROPDOWN (SAFE)
                    BlocBuilder<ConsultantCubit, ConsultantState>(
                      builder: (context, state) {
                        if (state is ConsultantLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (state is ConsultantLoaded) {
                          return DropdownButtonFormField<String>(
                            initialValue: selectedConsultantId, // 🚀 Show currently selected
                            hint: const Text('Select Consultant'),
                            decoration: InputDecoration(
                              labelText: 'Consultant',
                              fillColor: AppColors.greyTextFormFiledColor,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: state.consultants.map((consultant) {
                              return DropdownMenuItem<String>(
                                value: consultant.id,
                                child: Text(consultant.userName),
                              );
                            }).toList(),
                            onChanged: null, // 🚀 Read-only mode
                          );
                        }

                        if (state is ConsultantError) {
                          return Text(state.message);
                        }

                        return const SizedBox();
                      },
                    ),

                    verticalSpace20,

                    /// 🏢 DEPARTMENT HIERARCHY
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Department Hierarchy",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),

                    verticalSpaceSmall,

                    CustomerHierarchyCustom(
                      customer: widget.customer,
                    ),

                    verticalSpace20,
                  ],
                ),
              ),
            ),

            /// APPROVE BUTTON
            Padding(
              padding: const EdgeInsets.all(appHorizontalPadding15),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.customer.isProfileApproved ? Colors.green : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(appHorizontalPadding10),
                    ),
                  ),
                  onPressed: widget.customer.isProfileApproved
                      ? null
                      : () async {
                          if ((selectedConsultantId ?? "").isNotEmpty) {
                            await context.read<CustomerListCubit>().approveCustomer(
                                  customerId: widget.customer.customerId,
                                  companyName: widget.customer.companyName,
                                  customerEmail: widget.customer.email,
                                  consultantId: selectedConsultantId ?? '',
                                );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select consultant first."),
                              ),
                            );
                          }
                        },
                  child: Text(
                    widget.customer.isProfileApproved ? 'Approved' : 'Approve Customer',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
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
