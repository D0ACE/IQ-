import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/local_documents/cubit/local_document_state.dart';
import 'package:iq_plus/features/local_documents/models/local_document_model.dart';
import 'package:iq_plus/features/local_documents/repository/local_document_repository.dart';
import 'dart:developer' as developer;

class LocalDocumentCubit extends Cubit<LocalDocumentState> {
  final LocalDocumentRepository _repository;

  LocalDocumentCubit(this._repository) : super(LocalDocumentInitial());

  Future<void> loadDocuments() async {
    emit(LocalDocumentLoading());
    try {
      final docs = await _repository.getDocuments();
      // Sort by date descending
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(LocalDocumentLoaded(docs));
    } catch (e) {
      emit(LocalDocumentError(e.toString()));
    }
  }

  Future<void> addDocument(LocalDocumentModel document) async {
    emit(LocalDocumentLoading());
    try {
      developer.log("Adding local document: ${document.title}");
      await _repository.addDocument(document);
      developer.log("Local document added successfully: ${document.title}");
      emit(LocalDocumentOperationSuccess("Local document saved successfully"));
      loadDocuments();
    } catch (e) {
      developer.log("Error adding local document: $e");
      emit(LocalDocumentError(e.toString()));
    }
  }

  Future<void> saveRichDocument({
    String? docId,
    required String title,
    required String content,
  }) async {
    final isEdit = docId != null;
    DateTime? existingCreatedAt;
    
    if (isEdit && state is LocalDocumentLoaded) {
      try {
        existingCreatedAt = (state as LocalDocumentLoaded)
            .documents
            .firstWhere((d) => d.id == docId)
            .createdAt;
      } catch (_) {}
    }

    emit(LocalDocumentLoading());
    try {
      developer.log("${isEdit ? 'Updating' : 'Adding'} local rich document: $title");

      final doc = LocalDocumentModel(
        id: docId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        filePath: '', // No physical file for internal rich docs
        fileName: '$title.quill',
        fileType: '.quill',
        createdAt: existingCreatedAt ?? DateTime.now(),
      );

      if (isEdit) {
        await _repository.updateDocument(doc);
      } else {
        await _repository.addDocument(doc);
      }
      
      emit(LocalDocumentOperationSuccess("Local rich document saved successfully"));
      loadDocuments();
    } catch (e) {
      developer.log("Error saving local rich document: $e");
      emit(LocalDocumentError(e.toString()));
    }
  }

  Future<void> updateDocument(LocalDocumentModel document) async {
    emit(LocalDocumentLoading());
    try {
      developer.log("Updating local document: ${document.title}");
      await _repository.updateDocument(document);
      developer.log("Local document updated successfully: ${document.title}");
      emit(LocalDocumentOperationSuccess("Local document updated successfully"));
      loadDocuments();
    } catch (e) {
      developer.log("Error updating local document: $e");
      emit(LocalDocumentError(e.toString()));
    }
  }

  Future<void> deleteDocument(String id) async {
    emit(LocalDocumentLoading());
    try {
      developer.log("Deleting local document ID: $id");
      await _repository.deleteDocument(id);
      developer.log("Local document deleted successfully: $id");
      emit(LocalDocumentOperationSuccess("Local document deleted successfully"));
      loadDocuments();
    } catch (e) {
      developer.log("Error deleting local document: $e");
      emit(LocalDocumentError(e.toString()));
    }
  }
}
