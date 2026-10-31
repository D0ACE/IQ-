import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_state.dart';
import 'package:iq_plus/features/customer_mme/models/mme_model_req.dart';

class CustomerMMEFormPage extends StatefulWidget {
  final String customerId;
  final CustomerMMEModel? mme; // 👈 nullable for edit
  const CustomerMMEFormPage({super.key, required this.customerId,this.mme});

  bool get isEdit => mme != null;
  @override
  State<CustomerMMEFormPage> createState() => _CustomerMMEFormPageState();
}

class _CustomerMMEFormPageState extends State<CustomerMMEFormPage> {
  final _formKey = GlobalKey<FormState>();

  final serialCtrl = TextEditingController();
  final deviceCtrl = TextEditingController();
  final lastDateCtrl = TextEditingController();
  final nextDateCtrl = TextEditingController();

  DateTime? lastDate;
  DateTime? nextDate;

  @override
  void initState() {
    if (widget.mme != null) {
      final m = widget.mme!;

      serialCtrl.text = m.serialNumber;
      deviceCtrl.text = m.deviceName;

      lastDate = m.lastCalibrationDate;
      nextDate = m.nextCalibrationDate;

      lastDateCtrl.text =
          DateFormat('dd MMM yyyy').format(m.lastCalibrationDate);
      nextDateCtrl.text =
          DateFormat('dd MMM yyyy').format(m.nextCalibrationDate);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerMMECubit, CustomerMMEState>(
      listener: (context, state) {
        if (state is CustomerMMESuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEdit
                    ? 'MME Updated Successfully'
                    : 'MME Created Successfully',
              ),
            ),
          );
          context.read<CustomerMMECubit>().loadMME(widget.customerId);
          GoRouter.of(context).pop();
        }

        if (state is CustomerMMEError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(  title: Text(widget.isEdit ? 'Edit MME' : 'Add MME'),),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 🔢 Serial Number
                  _field(
                    AppTextFieldWidget(
                      hintText: "Serial Number",
                      textFieldController: serialCtrl,
                      isRequired: true,
                    ),
                  ),

                  /// 🛠 Device Name
                  _field(
                    AppTextFieldWidget(
                      hintText: "Device Name",
                      textFieldController: deviceCtrl,
                      isRequired: true,
                    ),
                  ),

                  /// 📅 Last Calibration Date
                  _field(
                    TextFormField(
                      controller: lastDateCtrl,
                      readOnly: true,
                      decoration:
                      _dropdownDecoration("Last Calibration Date"),
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? "Last calibration date required"
                          : null,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: lastDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            lastDate = pickedDate;
                            lastDateCtrl.text =
                                DateFormat('dd MMM yyyy')
                                    .format(pickedDate);
                            if (nextDate != null && nextDate!.isBefore(pickedDate)) {
                              nextDate = null;
                              nextDateCtrl.clear();
                            }
                          });
                        }
                      },
                    ),
                  ),

                  /// ⏭ Next Calibration Due Date
                  _field(
                    TextFormField(
                      controller: nextDateCtrl,
                      readOnly: true,
                      decoration:
                      _dropdownDecoration("Next Calibration Due Date"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Next calibration date required";
                        }
                        if (lastDate != null && nextDate != null) {
                          if (nextDate!.isBefore(lastDate!)) {
                            return "Next calibration due date cannot be before Last Calibration date";
                          }
                        }
                        return null;
                      },
                      onTap: () async {
                        if (lastDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select Last Calibration Date first"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final initial = (nextDate != null && nextDate!.isAfter(lastDate!))
                            ? nextDate!
                            : lastDate!.add(const Duration(days: 1));

                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: lastDate!,
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            nextDate = pickedDate;
                            nextDateCtrl.text =
                                DateFormat('dd MMM yyyy')
                                    .format(pickedDate);
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 💾 Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is CustomerMMELoading
                          ? null
                          : () {
                        if (!_formKey.currentState!.validate()) return;

                        if (widget.isEdit) {
                          context.read<CustomerMMECubit>().updateMME(
                            docId: widget.mme!.docId??"",
                            mmeId: widget.mme!.id,
                            customerId: widget.customerId,
                            device: deviceCtrl.text.trim(),
                            lastDate: lastDate!,
                            nextDate: nextDate!, serial: serialCtrl.text.trim(),
                          );
                        } else {
                          context.read<CustomerMMECubit>().createMME(
                          customerId: widget.customerId,
                          serial: serialCtrl.text.trim(),
                          device: deviceCtrl.text.trim(),
                          lastDate: lastDate!,
                          nextDate: nextDate!,
                        );
                        }
                      },
                      child: state is CustomerMMELoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// spacing helper
  Widget _field(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: child);

  /// same decoration used in your customer form
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: const Icon(Icons.calendar_today),
    );
  }
}
