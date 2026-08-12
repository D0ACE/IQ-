import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_cubit.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_state.dart';
import 'package:intl/intl.dart';
/*import 'package:open_file_plus/open_file_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;*/

class LocalDocumentListPage extends StatefulWidget {
  const LocalDocumentListPage({super.key});

  @override
  State<LocalDocumentListPage> createState() => _LocalDocumentListPageState();
}

class _LocalDocumentListPageState extends State<LocalDocumentListPage> {
  @override
  void initState() {
    super.initState();
    context.read<LocalDocumentCubit>().loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'Policies & Procedures (Local)'),
      floatingActionButton: FloatingActionButton(
        //onPressed: () => _showAddOptions(context),
        onPressed: (){
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
            final docs = state.documents;
            if (docs.isEmpty) {
              return const Center(child: Text('No local documents found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
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
                       /* IconButton(
                          tooltip: 'Open / Edit Locally in External App',
                          icon: const Icon(Icons.open_in_new, color: Colors.green),
                          onPressed: () => _openExternal(context, doc.filePath),
                        ),*/
                        IconButton(
                          tooltip: (isRichDoc || isDocx) ? 'Edit / Read Content' : 'Edit (Rich Text)',
                          icon: Icon(
                            isDocx ? Icons.chrome_reader_mode : Icons.edit_note, 
                            color: Colors.blue
                          ),
                          onPressed: () {
                            context.push(AppRoutes.documentEditor, extra: {
                              'document': doc,
                              'isLocal': true,
                            });
                          },
                        ),
                     /*   IconButton(
                          tooltip: 'Local File Settings',
                          icon: const Icon(Icons.settings, color: Colors.grey),
                          onPressed: () => context.push(AppRoutes.localDocumentAddEdit, extra: doc),
                        ),*/
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
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

/*  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt, color: AppColors.purple),
              title: const Text('Save Local File'),
              subtitle: const Text('Store a file locally on this device'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.localDocumentAddEdit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColors.purple),
              title: const Text('Create Local Rich Doc'),
              subtitle: const Text('Create a Word-like document stored locally'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.documentEditor, extra: {
                  'isLocal': true,
                });
              },
            ),
          ],
        ),
      ),
    );
  }*/

/*  Future<void> _openExternal(BuildContext context, String path) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening local files via path is not supported on Web.')));
      return;
    }

    if (path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local file not found on this device')));
      return;
    }
    await OpenFile.open(path);
  }*/

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
