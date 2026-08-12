import 'package:iq_plus/features/superadmin/models/document_model.dart';

abstract class DocumentState {}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<DocumentModel> documents;
  DocumentLoaded(this.documents);
}

class DocumentOperationSuccess extends DocumentState {
  final String message;
  DocumentOperationSuccess(this.message);
}

class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}
