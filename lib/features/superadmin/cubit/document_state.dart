import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';

abstract class DocumentState {}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<DocumentModel> documents;
  DocumentLoaded(this.documents);
}

class GlobalVersionHistoryLoaded extends DocumentState {
  final List<VersionHistoryModel> history;
  final bool hasMore;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  GlobalVersionHistoryLoaded({
    required this.history,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  GlobalVersionHistoryLoaded copyWith({
    List<VersionHistoryModel>? history,
    bool? hasMore,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return GlobalVersionHistoryLoaded(
      history: history ?? this.history,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

class DocumentOperationSuccess extends DocumentState {
  final String message;
  DocumentOperationSuccess(this.message);
}

class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}
