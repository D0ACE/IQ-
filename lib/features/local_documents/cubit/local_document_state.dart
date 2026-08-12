import 'package:iq_plus/features/local_documents/models/local_document_model.dart';

abstract class LocalDocumentState {}

class LocalDocumentInitial extends LocalDocumentState {}

class LocalDocumentLoading extends LocalDocumentState {}

class LocalDocumentLoaded extends LocalDocumentState {
  final List<LocalDocumentModel> documents;
  LocalDocumentLoaded(this.documents);
}

class LocalDocumentOperationSuccess extends LocalDocumentState {
  final String message;
  LocalDocumentOperationSuccess(this.message);
}

class LocalDocumentError extends LocalDocumentState {
  final String message;
  LocalDocumentError(this.message);
}
