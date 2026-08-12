import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:path/path.dart' as p;

class DocumentAddEditPage extends StatefulWidget {
  final DocumentModel? document;
  const DocumentAddEditPage({super.key, this.document});

  @override
  State<DocumentAddEditPage> createState() => _DocumentAddEditPageState();
}

class _DocumentAddEditPageState extends State<DocumentAddEditPage> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final changeDescriptionCtrl = TextEditingController();
  File? selectedFile;
  String? existingFileName;
  String? selectedCustomerId;
  String? selectedReviewerId;
  String? selectedReviewerName;

  bool get isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    context.read<CustomerListCubit>().fetchCustomers();
    context.read<ConsultantCubit>().fetchConsultants();
    
    if (isEdit) {
      titleCtrl.text = widget.document!.title;
      existingFileName = widget.document!.fileName;
      selectedCustomerId = widget.document!.customerId;
      selectedReviewerId = widget.document!.assignedReviewerId;
      selectedReviewerName = widget.document!.assignedReviewerName;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    changeDescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentCubit, DocumentState>(
      listener: (context, state) {
        if (state is DocumentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          context.pop();
        }
        if (state is DocumentError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: CommonAppBar(title: isEdit ? 'Edit Policy' : 'Add Policy'),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextFieldWidget(
                    hintText: "Policy Title",
                    textFieldController: titleCtrl,
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),

                  if (isEdit) ...[
                    AppTextFieldWidget(
                      hintText: "Description of the change",
                      textFieldController: changeDescriptionCtrl,
                      isRequired: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // 👥 Customer Dropdown
                  const Text("Select Customer", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  BlocBuilder<CustomerListCubit, CustomerListState>(
                    builder: (context, customerState) {
                      if (customerState is CustomerListLoaded) {
                        return DropdownButtonFormField<String>(
                          initialValue: selectedCustomerId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          hint: const Text("Select a Customer"),
                          items: customerState.customers.map((c) {
                            return DropdownMenuItem(
                              value: c.customerId,
                              child: Text(c.companyName),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedCustomerId = val),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),

                  const SizedBox(height: 20),

                  // 👨‍💼 Reviewer Dropdown
                  const Text("Assign Reviewer", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  BlocBuilder<ConsultantCubit, ConsultantState>(
                    builder: (context, consultantState) {
                      if (consultantState is ConsultantLoaded) {
                        return DropdownButtonFormField<String>(
                          initialValue: selectedReviewerId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          hint: const Text("Select Reviewer"),
                          items: consultantState.consultants.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.userName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedReviewerId = val;
                              selectedReviewerName = consultantState.consultants
                                  .firstWhere((c) => c.id == val)
                                  .userName;
                            });
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  const Text("Policy File", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, color: AppColors.purple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedFile != null
                                  ? p.basename(selectedFile!.path)
                                  : (existingFileName ?? "No file selected"),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text("Select File", style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isEdit) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (widget.document?.fileType.toLowerCase() == '.xlsx'){
                            context.push(AppRoutes.excelEditor, extra: widget.document);
                          } else {
                            context.push(AppRoutes.documentEditor, extra: widget.document);
                          }
                        },
                        icon: const Icon(Icons.edit_note, color: AppColors.purple),
                        label: const Text("Open in Policy Editor", style: TextStyle(color: AppColors.purple)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.purple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is DocumentLoading ? null : _saveDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state is DocumentLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEdit ? "Update Policy" : "Save Policy"),
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

  void _saveDocument() {
    if (!_formKey.currentState!.validate()) return;
    if (!isEdit && selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a file")));
      return;
    }

    if (isEdit) {
      context.read<DocumentCubit>().updateDocument(
            docId: widget.document!.docId,
            title: titleCtrl.text.trim(),
            newFile: selectedFile,
            currentFilePath: widget.document!.filePath,
            customerId: selectedCustomerId,
            assignedReviewerId: selectedReviewerId,
            assignedReviewerName: selectedReviewerName,
            changeDescription: changeDescriptionCtrl.text.trim(),
          );
    } else {
      context.read<DocumentCubit>().addDocument(
            title: titleCtrl.text.trim(),
            file: selectedFile!,
            customerId: selectedCustomerId,
            assignedReviewerId: selectedReviewerId,
            assignedReviewerName: selectedReviewerName,
          );
    }
  }
}
