import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/kpis/cubit/kpi_cubit.dart';
import 'package:iq_plus/features/kpis/cubit/kpi_state.dart';
import 'package:iq_plus/features/kpis/models/kpi_model.dart';
import 'package:iq_plus/common/utility/utility.dart';

class KpiFormPage extends StatefulWidget {
  final KpiTask? task;

  const KpiFormPage({super.key, this.task});

  @override
  State<KpiFormPage> createState() => _KpiFormPageState();
}

class _KpiFormPageState extends State<KpiFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;
  DateTime? _selectedDueDate;
  CustomerModel? _selectedCustomer;
  String _selectedTargetType = 'Percentage';
  bool _isAutoGenerate = false;
  String _selectedFrequency = 'Monthly';
  final List<String> _frequencies = ['Weekly', 'Monthly', 'Quarterly', 'Biannually', 'Annually'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _targetController = TextEditingController(
        text: (widget.task?.target ?? '').replaceAll('%', '').trim());
    _selectedDueDate = widget.task?.dueDate;
    _selectedTargetType = widget.task?.targetType ?? 'Percentage';
    _isAutoGenerate = widget.task?.isAutoGenerate ?? false;
    _selectedFrequency = widget.task?.frequency ?? 'Monthly';
    if (!_frequencies.contains(_selectedFrequency)) {
      _selectedFrequency = 'Monthly';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDate = (_selectedDueDate != null && _selectedDueDate!.isBefore(today))
        ? DateTime(_selectedDueDate!.year, _selectedDueDate!.month, _selectedDueDate!.day)
        : today;

    DateTime initialDate = _selectedDueDate ?? now.add(const Duration(days: 7));
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final lastDate = now.add(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  String _formatValue(String input, String targetType) {
    final clean = input.trim().replaceAll('%', '').trim();
    if (clean.isEmpty) return '';
    if (targetType == 'Percentage') {
      return '$clean%';
    } else {
      return clean;
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
        BlocProvider(create: (_) => getIt<KpiCubit>()),
      ],
      child: BlocListener<KpiCubit, KpiState>(
        listener: (context, state) {
          if (state is KpiActionSuccess) {
            if (mounted) {
              setState(() => _isSaving = false);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context, true);
          } else if (state is KpiError) {
            if (mounted) {
              setState(() => _isSaving = false);
            }
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
              widget.task == null ? "New KPI" : "Edit KPI",
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
                  _sectionHeader("KPI's Details"),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: "Enter KPI's title",
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: "Describe the KPI's requirement",
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader('Assignment'),
                  const SizedBox(height: 16),
                  BlocBuilder<CustomerListCubit, CustomerListState>(
                    builder: (context, state) {
                      List<CustomerModel> customers = [];
                      CustomerModel? matchedCustomer;
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

                      if (_selectedCustomer != null && _selectedCustomer!.customerId.isNotEmpty) {
                        final matches = customers.where((c) => c.customerId == _selectedCustomer!.customerId);
                        if (matches.length == 1) {
                          matchedCustomer = matches.first;
                        } else {
                          matchedCustomer = _selectedCustomer;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<CustomerModel>(
                            // ignore: deprecated_member_use
                            value: matchedCustomer,
                            decoration: _inputDecoration('Assign Customer', 'Select a customer'),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c.companyName),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCustomer = val),
                            validator: (v) => v == null ? 'Please select a customer' : null,
                          ),
                          if (_selectedCustomer != null || (widget.task != null && widget.task!.assignedCustomerId.isNotEmpty))
                            _buildLowerPersonDetails(),
                        ],
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
                  const SizedBox(height: 32),
                  _sectionHeader('Target'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTargetType,
                    decoration: _inputDecoration('Target Format', 'Select format'),
                    items: const [
                      DropdownMenuItem(value: 'Percentage', child: Text('Percentage (%)')),
                      DropdownMenuItem(value: 'Number', child: Text('Number')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTargetType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _targetController,
                    label: 'Target Value',
                    hint: _selectedTargetType == 'Percentage' ? 'e.g. 80%' : 'e.g. 100',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => _validateValue(val, 'Target', _selectedTargetType),
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader('Auto Generation'),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text(
                            'Auto generate task',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.titleText,
                            ),
                          ),
                          subtitle: const Text(
                            "Automatically create the next KPI based on frequency and due date",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: _isAutoGenerate,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _isAutoGenerate = val ?? false;
                            });
                          },
                        ),
                        if (_isAutoGenerate) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedFrequency,
                              decoration: _inputDecoration('Frequency', 'Select frequency'),
                              items: _frequencies.map((f) {
                                return DropdownMenuItem<String>(
                                  value: f,
                                  child: Text(f),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedFrequency = val);
                                }
                              },
                              validator: (v) => (_isAutoGenerate && (v == null || v.isEmpty))
                                  ? 'Please select a frequency'
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Builder(
                    builder: (ctx) => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonDarkGreen,
                          foregroundColor: AppColors.buttonYellow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving
                            ? null
                            : () {
                                if (_formKey.currentState!.validate() && user != null) {
                                  setState(() => _isSaving = true);
                                  final formattedTarget = _formatValue(_targetController.text, _selectedTargetType);

                                  final task = KpiTask(
                                    id: widget.task?.id ?? '',
                                    title: _titleController.text.trim(),
                                    description: _descriptionController.text.trim(),
                                    assignedCustomerId: _selectedCustomer!.customerId,
                                    assignedCustomerName: _selectedCustomer!.companyName,
                                    assignedCustomerLowLevelName: _selectedCustomer?.lowLevelName ?? widget.task?.assignedCustomerLowLevelName ?? '',
                                    assignedCustomerLowLevelEmail: _selectedCustomer?.lowLevelEmail ?? widget.task?.assignedCustomerLowLevelEmail ?? '',
                                    assignedCustomerLowLevelMobile: _selectedCustomer?.lowLevelMobile ?? widget.task?.assignedCustomerLowLevelMobile ?? '',
                                    assignedCustomerMediumLevelName: _selectedCustomer?.mediumLevelName ?? widget.task?.assignedCustomerMediumLevelName ?? '',
                                    assignedCustomerMediumLevelEmail: _selectedCustomer?.mediumLevelEmail ?? widget.task?.assignedCustomerMediumLevelEmail ?? '',
                                    assignedCustomerMediumLevelMobile: _selectedCustomer?.mediumLevelMobile ?? widget.task?.assignedCustomerMediumLevelMobile ?? '',
                                    target: formattedTarget,
                                    achieved: widget.task?.achieved ?? '',
                                    targetType: _selectedTargetType,
                                    achievedType: widget.task?.achievedType ?? 'Percentage',
                                    dueDate: _selectedDueDate!,
                                    status: widget.task?.status ?? 'open',
                                    createdAt: widget.task?.createdAt ?? DateTime.now(),
                                    createdBy: user.userId,
                                    createdByName: user.userName,
                                    evidenceUrl: widget.task?.evidenceUrl ?? '',
                                    evidenceFileName: widget.task?.evidenceFileName ?? '',
                                    isAutoGenerate: _isAutoGenerate,
                                    frequency: _selectedFrequency,
                                    comment: widget.task?.comment ?? '',
                                  );

                                  if (widget.task == null) {
                                    ctx.read<KpiCubit>().addTask(task);
                                  } else {
                                    ctx.read<KpiCubit>().updateTask(task);
                                  }
                                }
                              },
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.buttonYellow,
                                ),
                              )
                            : Text(
                                widget.task == null ? "CREATE KPI" : "UPDATE KPI",
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

  Widget _buildLowerPersonDetails() {
    final name = _selectedCustomer?.lowLevelName ?? widget.task?.assignedCustomerLowLevelName ?? '';
    final email = _selectedCustomer?.lowLevelEmail ?? widget.task?.assignedCustomerLowLevelEmail ?? '';
    final phone = _selectedCustomer?.lowLevelMobile ?? widget.task?.assignedCustomerLowLevelMobile ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lower Person Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _lowerPersonInfoRow(Icons.person_outline, 'Name', name.isNotEmpty ? name : 'N/A'),
          const SizedBox(height: 8),
          _lowerPersonInfoRow(Icons.email_outlined, 'Email', email.isNotEmpty ? email : 'N/A'),
          const SizedBox(height: 8),
          _lowerPersonInfoRow(Icons.phone_outlined, 'Phone', phone.isNotEmpty ? AppValidation.formatPhoneForDisplay(phone) : 'N/A'),
        ],
      ),
    );
  }

  Widget _lowerPersonInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.titleText),
          ),
        ),
      ],
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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

  String? _validateValue(String? val, String fieldName, String targetType) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName is required';
    }
    final cleanVal = val.trim().replaceAll('%', '').trim();
    final numVal = double.tryParse(cleanVal);
    if (numVal == null) {
      return 'Enter a valid numeric value';
    }
    if (targetType == 'Percentage') {
      if (numVal < 0 || numVal > 100) {
        return 'Percentage must be between 0 and 100';
      }
    } else {
      if (numVal < 0) {
        return 'Value must be 0 or greater';
      }
    }
    return null;
  }
}
