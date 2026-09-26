import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_cubit.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_state.dart';
import 'package:intl/intl.dart';

class LocalDocumentListPage extends StatefulWidget {
  const LocalDocumentListPage({super.key});

  @override
  State<LocalDocumentListPage> createState() => _LocalDocumentListPageState();
}

class _LocalDocumentListPageState extends State<LocalDocumentListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<LocalDocumentCubit>().loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredDocuments(List<dynamic> docs) {
    if (_searchQuery.isEmpty) return docs;
    final q = _searchQuery.toLowerCase().trim();
    return docs.where((doc) {
      final title = (doc.title ?? '').toString().toLowerCase();
      final fileName = (doc.fileName ?? '').toString().toLowerCase();
      final fileType = (doc.fileType ?? '').toString().toLowerCase();
      return title.contains(q) || fileName.contains(q) || fileType.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'Policies & Procedures (Local)'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.documentEditor, extra: {
            'isLocal': true,
          });
        },
        backgroundColor: AppColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<LocalDocumentCubit, LocalDocumentState>(
        builder: (context, state) {
          if (state is LocalDocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LocalDocumentError) {
            return Center(child: Text(state.message));
          }
          if (state is LocalDocumentLoaded) {
            final allDocs = state.documents;
            if (allDocs.isEmpty) {
              return const Center(child: Text('No local documents found'));
            }

            final filteredDocs = _getFilteredDocuments(allDocs);

            return Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search local policies...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.kPrimaryColor,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                if (_searchQuery.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Showing ${filteredDocs.length} of ${allDocs.length} local policies",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.titleText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.close_rounded, size: 14, color: AppColors.kPrimaryColor),
                              SizedBox(width: 4),
                              Text(
                                "Clear search",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: filteredDocs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 60,
                                color: AppColors.grey40TextColor,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No matching local policies found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey70TextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                label: const Text("Clear Search"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final isRichDoc = doc.content != null;
                            final isDocx = doc.fileName.toLowerCase().endsWith('.docx');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.kPrimaryLightColor,
                                  child: Icon(
                                    isRichDoc ? Icons.article : _getFileIcon(doc.fileType),
                                    color: AppColors.purple,
                                  ),
                                ),
                                title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  isRichDoc
                                      ? "Local Rich Document\nLast updated: ${DateFormat('dd MMM yyyy').format(doc.createdAt)}"
                                      : "${doc.fileName}\nSaved on: ${DateFormat('dd MMM yyyy').format(doc.createdAt)}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: (isRichDoc || isDocx) ? 'Edit / Read Content' : 'Edit (Rich Text)',
                                      icon: Icon(
                                        isDocx ? Icons.chrome_reader_mode : Icons.edit_note,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        context.push(AppRoutes.documentEditor, extra: {
                                          'document': doc,
                                          'isLocal': true,
                                        });
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(context, doc.id),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('doc')) return Icons.description;
    if (type.contains('xls')) return Icons.table_chart;
    if (type.contains('jpg') || type.contains('png')) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Local Document'),
        content: const Text('Are you sure you want to delete this document locally?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<LocalDocumentCubit>().deleteDocument(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
