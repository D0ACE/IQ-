import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CustomerPolicyDetailPage extends StatefulWidget {
  final DocumentModel? document;
  final String? docId;
  const CustomerPolicyDetailPage({super.key, this.document, this.docId});

  @override
  State<CustomerPolicyDetailPage> createState() => _CustomerPolicyDetailPageState();
}

class _CustomerPolicyDetailPageState extends State<CustomerPolicyDetailPage> {
  DocumentModel? _document;
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _initializeController();
  }

  Future<void> _initializeController() async {
    // 1. Fetch document if not provided
    if (_document == null && widget.docId != null) {
      _document = await DocumentRepository().getDocumentById(widget.docId!);
    }

    if (_document == null) {
      if (mounted) setState(() => _isLoading = false);
      _controller = _createReadOnlyBasicController();
      return;
    }

    // 2. Parse content if exists
    if (_document!.content != null && _document!.content!.isNotEmpty) {
      try {
        // Offload heavy JSON decoding and Document creation to a background isolate
        final document = await compute(_parseDocument, _document!.content!);
        
        if (mounted) {
          setState(() {
            _controller = QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
              readOnly: true,
            );
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _controller = _createReadOnlyBasicController();
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _controller = _createReadOnlyBasicController();
          _isLoading = false;
        });
      }
    }
  }

  // Top-level or static function required for compute
  static Document _parseDocument(String content) {
    return Document.fromJson(jsonDecode(content));
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
    if (_document == null) return;
    final url = Uri.parse(_document!.fileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a global loader if document isn't even metadata-ready
    if (_document == null && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Policy not found")),
      );
    }

    final bool hasContent = _document!.content != null && _document!.content!.isNotEmpty;
    final bool hasFile = _document!.fileUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(title: _document!.title),
      body: Stack(
        children: [
          // 🎨 Optimized Dot Pattern Background (Non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  dotColor: AppColors.kPrimaryColor.withOpacity(0.05),
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              // 🚀 Neo-Modern Floating Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kPrimaryColor.withOpacity(0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "VERSION ${_document!.currentVersion}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _document!.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _document!.status == 'active' ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _infoBlockModern("Prepared By", _document!.createdBy, Icons.edit_note_rounded, true)),
                          Expanded(child: _infoBlockModern("Prepared Date", DateFormat('dd MMM yyyy').format(_document!.createdAt), Icons.calendar_today_rounded, true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _infoBlockModern("Reviewed By", _document!.reviewedBy ?? "N/A", Icons.rate_review_rounded, true)),
                          Expanded(child: _infoBlockModern("Reviewed Date", _document!.reviewedDate != null ? DateFormat('dd MMM yyyy').format(_document!.reviewedDate!) : "N/A", Icons.event_available_rounded, true)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 👁 Content Viewer Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _isLoading 
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AppColors.kPrimaryColor),
                              SizedBox(height: 16),
                              Text(
                                "Loading document...",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : hasContent 
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
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryLightColor.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.file_present_rounded, size: 64, color: AppColors.kPrimaryColor),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _document!.fileName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.titleText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "This policy is available for download",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.subText.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (hasFile)
                                ElevatedButton.icon(
                                  onPressed: _downloadFile,
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text("Download & View File"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 8,
                                    shadowColor: AppColors.kPrimaryColor.withOpacity(0.4),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlockModern(String label, String value, IconData icon, bool isInverse) {
    final Color textColor = isInverse ? Colors.white : AppColors.titleText;
    final Color subColor = isInverse ? Colors.white.withOpacity(0.6) : AppColors.subText.withOpacity(0.6);

    return Row(
      children: [
        Icon(icon, size: 16, color: subColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: subColor,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  _DotPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 30.0;
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final List<Offset> points = [];
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
