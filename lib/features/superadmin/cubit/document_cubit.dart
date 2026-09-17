import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'dart:developer' as developer;

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentRepository _repository;
  String? _lastUserId;
  bool _lastIsConsultant = false;
  String? _lastCustomerId;

  DocumentCubit(this._repository) : super(DocumentInitial());

  Future<void> loadDocuments({String? userId, bool isConsultant = false, String? customerId}) async {
    _lastUserId = userId;
    _lastIsConsultant = isConsultant;
    _lastCustomerId = customerId;
    
    emit(DocumentLoading());
    try {
      final docs = await _repository.getDocuments(
        userId: userId, 
        isConsultant: isConsultant,
        customerId: customerId,
      );
      emit(DocumentLoaded(docs));
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  void _refresh() {
    loadDocuments(
      userId: _lastUserId, 
      isConsultant: _lastIsConsultant,
      customerId: _lastCustomerId,
    );
  }

  Future<void> addDocument({
    required String title,
    required Uint8List bytes,
    required String fileName,
    String? customerId,
  }) async {
    emit(DocumentLoading());
    try {
      developer.log("Adding policy to Supabase/Firestore: $title for customer: $customerId");
      await _repository.addDocument(
        title: title,
        bytes: bytes,
        fileName: fileName,
        customerId: customerId,
      );
      emit(DocumentOperationSuccess("Policy uploaded successfully"));
      _refresh();
    } catch (e) {
      developer.log("Error adding policy: $e");
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> saveRichDocument({
    String? docId,
    required String title,
    required String content,
    String? customerId,
    String? changeDescription,
  }) async {
    emit(DocumentLoading());
    try {
      developer.log("${docId == null ? 'Adding' : 'Updating'} rich policy");
      await _repository.saveRichDocument(
        docId: docId,
        title: title,
        content: content,
        customerId: customerId,
        changeDescription: changeDescription,
      );
      emit(DocumentOperationSuccess("Rich policy saved successfully"));
      _refresh();
    } catch (e) {
      developer.log("Error saving rich policy: $e");
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> saveExcelDocument({
    String? docId,
    required String title,
    required Uint8List bytes,
    String? customerId,
    String? currentFilePath,
    String? changeDescription,
    bool isContentChanged = true, // 👈 New parameter
  }) async {
    emit(DocumentLoading());
    try {
      await _repository.saveExcelBytes(
        docId: docId,
        title: title,
        bytes: bytes,
        customerId: customerId,
        currentFilePath: currentFilePath,
        changeDescription: changeDescription,
        isContentChanged: isContentChanged,
      );
      emit(DocumentOperationSuccess("Excel policy saved successfully"));
      _refresh();
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> updateDocument({
    required String docId,
    required String title,
    Uint8List? newFileBytes,
    String? newFileName,
    String? currentFilePath,
    String? customerId,
    String? changeDescription,
  }) async {
    emit(DocumentLoading());
    try {
      developer.log("Updating policy ID: $docId");
      await _repository.updateDocument(
        docId: docId,
        title: title,
        newFileBytes: newFileBytes,
        newFileName: newFileName,
        currentFilePath: currentFilePath,
        customerId: customerId,
        changeDescription: changeDescription,
      );
      emit(DocumentOperationSuccess("Policy updated successfully"));
      _refresh();
    } catch (e) {
      developer.log("Error updating policy: $e");
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> deleteDocument(String docId, String? supabasePath) async {
    emit(DocumentLoading());
    try {
      developer.log("Deleting policy from Supabase/Firestore: $docId");
      await _repository.deleteDocument(docId, supabasePath);
      emit(DocumentOperationSuccess("Policy deleted successfully"));
      _refresh();
    } catch (e) {
      developer.log("Error deleting policy: $e");
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> updateStatus(String docId, String status) async {
    emit(DocumentLoading());
    try {
      await _repository.updateStatus(docId, status);
      _refresh();
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> loadGlobalVersionHistory({
    String? userId,
    bool isConsultant = false,
    String? customerId,
  }) async {
    emit(DocumentLoading());
    try {
      final history = await _repository.getGlobalVersionHistory(
        userId: userId,
        isConsultant: isConsultant,
        customerId: customerId,
      );
      emit(GlobalVersionHistoryLoaded(history));
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }
}
