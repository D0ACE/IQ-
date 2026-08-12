import 'package:hive/hive.dart';
import 'package:iq_plus/features/local_documents/models/local_document_model.dart';

class LocalDocumentRepository {
  static const String boxName = 'localDocumentsBox';

  Future<Box<LocalDocumentModel>> get _box async =>
      await Hive.openBox<LocalDocumentModel>(boxName);

  Future<List<LocalDocumentModel>> getDocuments() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<void> addDocument(LocalDocumentModel document) async {
    final box = await _box;
    await box.put(document.id, document);
  }

  Future<void> updateDocument(LocalDocumentModel document) async {
    final box = await _box;
    await box.put(document.id, document);
  }

  Future<void> deleteDocument(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
