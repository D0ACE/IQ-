import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_state.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

// 📄 Word Processing Imports
import 'package:docx_creator/docx_creator.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// 📑 PDF & Excel Imports
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentEditorPage extends StatefulWidget {
  final dynamic document;
  const DocumentEditorPage({super.key, this.document});

  @override
  State<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends State<DocumentEditorPage> {
  late QuillController _controller;
  final titleCtrl = TextEditingController();
  final changeDescriptionCtrl = TextEditingController();
  
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? selectedCustomerId;
  String? selectedReviewerId;
  String? selectedReviewerName;
  final _currentUser = getIt<HiveService>().getUser();

  // 🔄 Re-upload support
  Uint8List? selectedFileBytes;
  String? selectedFileName;

  // 🔄 Change Tracking
  String? _initialTitle;

  // 🧊 Stable configurations to prevent blinking
  late List<EmbedBuilder> _editorEmbedBuilders;
  late List<EmbedButtonBuilder> _toolbarEmbedButtons;

  @override
  void initState() {
    super.initState();
    
    // Initialize stable configurations with table support
    _editorEmbedBuilders = FlutterQuillEmbeds.editorBuilders();
    _toolbarEmbedButtons = FlutterQuillEmbeds.toolbarButtons();

    // Initialize with a safe default
    _controller = QuillController.basic();
    
    // Fetch reviewers for dropdown
    context.read<ConsultantCubit>().fetchConsultants();

    if (widget.document != null) {
      _initialTitle = widget.document.title ?? '';
      titleCtrl.text = _initialTitle!;
      selectedCustomerId = widget.document.customerId;
      selectedReviewerId = widget.document.assignedReviewerId;
      selectedReviewerName = widget.document.assignedReviewerName;
      _loadDocumentContent();
    } else {
      _initialTitle = '';
    }
  }

  Future<void> _loadDocumentContent() async {
    final String? content = widget.document.content;
    final String? fileUrl = widget.document.fileUrl;
    final String fileName = widget.document.fileName ?? '';

    setState(() => _isLoading = true);

    try {
      // 1. Try loading from Rich Text Content (Delta JSON)
      if (content != null && content.isNotEmpty) {
        try {
          final dynamic json = jsonDecode(content);
          if (json is List) {
            final delta = Delta.fromJson(json);
            _updateEditorContent(delta);
            developer.log("Rich text loaded as Delta JSON");
            if (mounted) setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          developer.log("Content was not valid JSON, trying other methods");
        }
      }

      // 2. High-Fidelity Workflow: DOCX -> HTML -> Delta -> Editor
      if (fileName.toLowerCase().endsWith('.docx')) {
        Uint8List bytes;
        if (fileUrl != null && fileUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(fileUrl));
          bytes = response.bodyBytes;
        } else {
          throw Exception("No valid file source");
        }

        final docModel = await DocxReader.loadFromBytes(bytes);
        final htmlContent = HtmlExporter().export(docModel);
        final sanitizedHtml = _sanitizeHtmlForQuill(htmlContent);
        final delta = HtmlToDelta().convert(sanitizedHtml);
        
        _updateEditorContent(delta);
        developer.log("Loaded HTML content from DOCX into Editor");
      } else if (content != null && content.isNotEmpty) {
        _loadAsPlainText(content);
      }
    } catch (e) {
      developer.log("Error processing document content: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateEditorContent(Delta delta) {
    if (!mounted) return;
    setState(() {
      _controller.document = Document.fromDelta(_ensureNewline(delta));
      if (widget.document != null && widget.document.fileType.toLowerCase() != '.quill') {
        _controller.readOnly = true;
      }
    });
  }

  void _loadAsPlainText(String text) {
    _updateEditorContent(Delta()..insert(text));
  }

  Delta _ensureNewline(Delta delta) {
    if (delta.isEmpty) return Delta()..insert('\n');
    try {
      final lastOp = delta.last;
      if (lastOp.isInsert && lastOp.data is String && (lastOp.data as String).endsWith('\n')) {
        return delta;
      }
    } catch (_) {}
    return delta..insert('\n');
  }

  @override
  void dispose() {
    _controller.dispose();
    titleCtrl.dispose();
    changeDescriptionCtrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CommonAppBar(
        title: widget.document == null ? 'Create Policy' : 'Edit Policy',
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isLoading,
            child: Column(
              children: [
                // 📝 Policy Header Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Column(
                    children: [
                      AppTextFieldWidget(
                        hintText: "Policy Title",
                        textFieldController: titleCtrl,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      if (widget.document != null) ...[
                        AppTextFieldWidget(
                          hintText: "Description of the change",
                          textFieldController: changeDescriptionCtrl,
                          isRequired: true,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      Row(
                        children: [
                          // 👥 Customer Dropdown
                          Expanded(
                            child: CustomerDropdownWidget(
                              hint: "Select Customer *",
                              selectedCustomer: selectedCustomerId != null 
                                  ? CustomerModel(
                                      customerId: selectedCustomerId!,
                                      companyName: '', email: '', phoneNumber: '', password: '', 
                                      certificateStandard: '', numberOfLocations: '', numberOfEmployees: '', 
                                      companyFunction: '', legitDocumentUrl: '', isProfileApproved: true, 
                                      fcmToken: '', roleId: '', createdAt: DateTime.now(), address: '', 
                                      lowLevelName: '', lowLevelEmail: '', lowLevelMobile: '', 
                                      mediumLevelName: '', mediumLevelEmail: '', mediumLevelMobile: '', 
                                      topLevelName: '', topLevelEmail: '', topLevelMobile: ''
                                    )
                                  : null,
                              consultantId: Utility.isConsultant(_currentUser?.roleId) ? _currentUser?.userId : null,
                              onChanged: (customer) {
                                setState(() {
                                  selectedCustomerId = customer?.customerId;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 👨‍💼 Reviewer Dropdown
                          Expanded(
                            child: BlocBuilder<ConsultantCubit, ConsultantState>(
                              builder: (context, consultantState) {
                                if (consultantState is ConsultantLoaded) {
                                  return DropdownButtonFormField<String>(
                                    initialValue: selectedReviewerId, // 🚀 Pre-select assigned consultant
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      labelText: "Assign Reviewer",
                                      labelStyle: const TextStyle(color: AppColors.purple),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                    hint: const Text("Assign Reviewer"),
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
                                return const LinearProgressIndicator();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),

                // 🖥 Editor / Preview Section
                if (widget.document != null && widget.document.fileType.toLowerCase() != '.quill')
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryLightColor.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getFileIcon(widget.document.fileType),
                                size: 64,
                                color: AppColors.kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              selectedFileName ?? widget.document.fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Uploaded Policy File",
                              style: TextStyle(color: AppColors.greyTextColor),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => launchUrl(Uri.parse(widget.document.fileUrl)),
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text("Download & View File"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _importFromFile,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text("Re-upload"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Standard Editor for .quill or New Documents
                  QuillSimpleToolbar(
                    controller: _controller,
                    config: QuillSimpleToolbarConfig(
                      showSearchButton: true,
                      showFontFamily: true,
                      showFontSize: true,
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showStrikeThrough: true,
                      showColorButton: true,
                      showBackgroundColorButton: true,
                      showListNumbers: true,
                      showListBullets: true,
                      showListCheck: true,
                      showCodeBlock: true,
                      showQuote: true,
                      showIndent: true,
                      showLink: true,
                      showDirection: true,
                      showAlignmentButtons: true,
                      showUndo: true,
                      showRedo: true,
                      multiRowsDisplay: true,
                      embedButtons: _toolbarEmbedButtons,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: QuillEditor.basic(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: QuillEditorConfig(
                          placeholder: 'Start typing policy content...',
                          autoFocus: false,
                          expands: true,
                          padding: EdgeInsets.zero,
                          embedBuilders: _editorEmbedBuilders,
                        ),
                      ),
                    ),
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _saveDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.document == null ? 'Save' : 'Update'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _saveDocument() {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    if (widget.document != null && changeDescriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter description of the change')));
      return;
    }

    if (widget.document != null && widget.document.fileType.toLowerCase() != '.quill') {
      // 🚀 Handle Uploaded Policy Update (Metadata + File)
      context.read<DocumentCubit>().updateDocument(
            docId: widget.document.docId,
            title: titleCtrl.text.trim(),
            newFileBytes: selectedFileBytes,
            newFileName: selectedFileName,
            currentFilePath: widget.document.filePath,
            customerId: selectedCustomerId,
            assignedReviewerId: selectedReviewerId,
            assignedReviewerName: selectedReviewerName,
            changeDescription: changeDescriptionCtrl.text.trim(),
          );
    } else {
      // 🚀 Handle Rich Text Document
      final currentContentDelta = _controller.document.toDelta();
      final jsonContent = jsonEncode(currentContentDelta.toJson());
      final title = titleCtrl.text.trim();

      context.read<DocumentCubit>().saveRichDocument(
            docId: widget.document?.docId,
            title: title,
            content: jsonContent,
            customerId: selectedCustomerId,
            assignedReviewerId: selectedReviewerId,
            assignedReviewerName: selectedReviewerName,
            changeDescription: changeDescriptionCtrl.text.trim(),
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Policy updated successfully!')),
    );
    context.pop();
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isLoading = true);

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception("Could not read file bytes");
      
      setState(() {
        selectedFileBytes = bytes;
        selectedFileName = file.name;
        _isLoading = false;
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New file selected. Click Save to upload.")),
      );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }


  String _sanitizeHtmlForQuill(String html) {
    return html
      .replaceAll('text-align:center', 'text-align: center;')
      .replaceAll('text-align:right', 'text-align: right;')
      .replaceAll('text-align:justify', 'text-align: justify;')
      .replaceAll('align="center"', 'style="text-align: center;"')
      .replaceAll('align="right"', 'style="text-align: right;"')
      .replaceAll('align="justify"', 'style="text-align: justify;"');
  }

  IconData _getFileIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('doc')) return Icons.description;
    if (t.contains('xls')) return Icons.table_chart;
    if (t.contains('quill')) return Icons.edit_note;
    return Icons.insert_drive_file;
  }
}
