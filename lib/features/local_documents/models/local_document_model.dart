import 'package:hive/hive.dart';

part 'local_document_model.g.dart';

@HiveType(typeId: 3)
class LocalDocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final String fileName;

  @HiveField(4)
  final String fileType;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? content;

  LocalDocumentModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.createdAt,
    this.content,
  });
}
