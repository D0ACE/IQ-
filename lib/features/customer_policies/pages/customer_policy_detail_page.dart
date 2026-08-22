import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CustomerPolicyDetailPage extends StatefulWidget {
  final DocumentModel document;
  const CustomerPolicyDetailPage({super.key, required this.document});

  @override
  State<CustomerPolicyDetailPage> createState() => _CustomerPolicyDetailPageState();
}

class _CustomerPolicyDetailPageState extends State<CustomerPolicyDetailPage> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.document.content != null && widget.document.content!.isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(widget.document.content!));
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true, 
        );
      } catch (e) {
        _controller = _createReadOnlyBasicController();
      }
    } else {
      _controller = _createReadOnlyBasicController();
    }
  }

  QuillController _createReadOnlyBasicController() {
    return QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _downloadFile() async {
    final url = Uri.parse(widget.document.fileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasContent = widget.document.content != null && widget.document.content!.isNotEmpty;
    final bool hasFile = widget.document.fileUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CommonAppBar(title: widget.document.title),
      body: Column(
        children: [
          // 📄 Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Version: ${widget.document.currentVersion}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (widget.document.status == 'active' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.document.status.toUpperCase(), 
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          color: widget.document.status == 'active' ? Colors.green : Colors.orange
                        )
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _infoBlock("Prepared By", widget.document.createdBy)),
                    Expanded(child: _infoBlock("Prepared Date", DateFormat('dd MMM yyyy').format(widget.document.createdAt))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _infoBlock("Reviewed By", widget.document.reviewedBy ?? "N/A")),
                    Expanded(child: _infoBlock("Reviewed Date", widget.document.reviewedDate != null ? DateFormat('dd MMM yyyy').format(widget.document.reviewedDate!) : "N/A")),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 👁 Content Viewer
          Expanded(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: hasContent 
                ? QuillEditor.basic(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    config: const QuillEditorConfig(
                      expands: true,
                      padding: EdgeInsets.zero,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_present_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          widget.document.fileName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        if (hasFile)
                          ElevatedButton.icon(
                            onPressed: _downloadFile,
                            icon: const Icon(Icons.download),
                            label: const Text("Download & View File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
