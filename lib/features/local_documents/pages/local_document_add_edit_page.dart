import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_cubit.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_state.dart';
import 'package:iq_plus/features/local_documents/models/local_document_model.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDocumentAddEditPage extends StatefulWidget {
  final LocalDocumentModel? document;
  const LocalDocumentAddEditPage({super.key, this.document});

  @override
  State<LocalDocumentAddEditPage> createState() => _LocalDocumentAddEditPageState();
}

class _LocalDocumentAddEditPageState extends State<LocalDocumentAddEditPage> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  File? selectedFile;
  String? existingFileName;
  String? existingFilePath;

  bool get isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      titleCtrl.text = widget.document!.title;
      existingFileName = widget.document!.fileName;
      existingFilePath = widget.document!.filePath;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      if (!mounted) return;
      if (kIsWeb) {
        // 🌐 Web: Only have bytes and name
        setState(() {
           existingFileName = result.files.single.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File selected. Paths are not available on Web.')));
      } else if (result.files.single.path != null) {
        // 📱 Mobile/Desktop: Have real paths
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalDocumentCubit, LocalDocumentState>(
      listener: (context, state) {
        if (state is LocalDocumentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          context.pop();
        }
        if (state is LocalDocumentError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: CommonAppBar(title: isEdit ? 'Edit Local Document' : 'Add Local Document'),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextFieldWidget(
                    hintText: "Document Title",
                    textFieldController: titleCtrl,
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),
                  const Text("Document File (Local)", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          context.push(AppRoutes.documentEditor, extra: {
                            'document': widget.document,
                            'isLocal': true,
                          });
                        },
                        icon: const Icon(Icons.edit_note, color: AppColors.purple),
                        label: const Text("OPEN IN RICH DOCUMENT EDITOR", style: TextStyle(color: AppColors.buttonYellow)),
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
                      onPressed: state is LocalDocumentLoading ? null : _saveDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonDarkGreen,
                        foregroundColor: AppColors.buttonYellow,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state is LocalDocumentLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEdit ? "Update Locally" : "Save Locally"),
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
    
    if (kIsWeb) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local file storage is not supported on Web. Please use Firebase storage.')));
       return;
    }

    if (!isEdit && selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a file")));
      return;
    }

    if (isEdit) {
      final doc = LocalDocumentModel(
        id: widget.document!.id,
        title: titleCtrl.text.trim(),
        filePath: selectedFile?.path ?? existingFilePath!,
        fileName: selectedFile != null ? p.basename(selectedFile!.path) : existingFileName!,
        fileType: selectedFile != null ? p.extension(selectedFile!.path) : widget.document!.fileType,
        createdAt: widget.document!.createdAt,
      );
      context.read<LocalDocumentCubit>().updateDocument(doc);
    } else {
      final doc = LocalDocumentModel(
        id: const Uuid().v4(),
        title: titleCtrl.text.trim(),
        filePath: selectedFile!.path,
        fileName: p.basename(selectedFile!.path),
        fileType: p.extension(selectedFile!.path),
        createdAt: DateTime.now(),
      );
      context.read<LocalDocumentCubit>().addDocument(doc);
    }
  }
}
