import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_cubit.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_state.dart';
import 'package:iq_plus/features/periodic_compliance/models/periodic_compliance_model.dart';
import 'package:iq_plus/common/utility/utility.dart';

class PeriodicComplianceFormPage extends StatefulWidget {
  final PeriodicComplianceTask? task;

  const PeriodicComplianceFormPage({super.key, this.task});

  @override
  State<PeriodicComplianceFormPage> createState() => _PeriodicComplianceFormPageState();
}

class _PeriodicComplianceFormPageState extends State<PeriodicComplianceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDueDate;
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = getIt<HiveService>().getUser();
    final bool isConsultant = Utility.isConsultant(user?.roleId);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = getIt<CustomerListCubit>();
            if (isConsultant) {
              cubit.fetchApprovedCustomers(user?.userId);
            } else {
              cubit.fetchCustomers();
            }
            return cubit;
          },
        ),
        BlocProvider(create: (_) => getIt<PeriodicComplianceCubit>()),
      ],
      child: BlocListener<PeriodicComplianceCubit, PeriodicComplianceState>(
        listener: (context, state) {
          if (state is PeriodicComplianceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context, true);
          } else if (state is PeriodicComplianceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.titleText,
            title: Text(
              widget.task == null ? 'New Compliance Task' : 'Edit Compliance Task',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Task Details'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Enter task title',
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe the compliance requirement',
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader('Assignment'),
                  const SizedBox(height: 16),
                  BlocBuilder<CustomerListCubit, CustomerListState>(
                    builder: (context, state) {
                      List<CustomerModel> customers = [];
                      if (state is CustomerListLoaded) {
                        customers = state.customers;
                        if (widget.task != null && _selectedCustomer == null) {
                          try {
                            _selectedCustomer = customers.firstWhere(
                              (c) => c.customerId == widget.task!.assignedCustomerId,
                            );
                          } catch (_) {}
                        }
                      }

                      return DropdownButtonFormField<CustomerModel>(
                        value: _selectedCustomer,
                        decoration: _inputDecoration('Assign Customer', 'Select a customer'),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.companyName),
                          );
                        }).toList(),
                        onChanged: widget.task != null
                            ? null // Disable changing customer on edit if desired, or keep enabled
                            : (val) => setState(() => _selectedCustomer = val),
                        validator: (v) => v == null ? 'Please select a customer' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _pickDate,
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: _selectedDueDate == null
                              ? ''
                              : DateFormat('dd MMM yyyy').format(_selectedDueDate!),
                        ),
                        decoration: _inputDecoration('Due Date', 'Select deadline').copyWith(
                          suffixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        ),
                        validator: (v) => v!.isEmpty ? 'Due date is required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Builder(
                    builder: (ctx) => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate() && user != null) {
                            final task = PeriodicComplianceTask(
                              id: widget.task?.id ?? '',
                              title: _titleController.text.trim(),
                              description: _descriptionController.text.trim(),
                              assignedCustomerId: _selectedCustomer!.customerId,
                              assignedCustomerName: _selectedCustomer!.companyName,
                              dueDate: _selectedDueDate!,
                              status: widget.task?.status ?? 'pending',
                              createdAt: widget.task?.createdAt ?? DateTime.now(),
                              createdBy: user.userId,
                              createdByName: user.userName,
                            );

                            if (widget.task == null) {
                              ctx.read<PeriodicComplianceCubit>().addTask(task);
                            } else {
                              ctx.read<PeriodicComplianceCubit>().updateTask(task);
                            }
                          }
                        },
                        child: Text(
                          widget.task == null ? 'CREATE TASK' : 'UPDATE TASK',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                        ),
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

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
