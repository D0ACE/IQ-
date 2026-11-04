abstract class BaseDownloader {
  void downloadTextFile({
    required String content,
    required String fileName,
    String mimeType = 'text/csv;charset=utf-8;',
  });
}

class FileDownloader {
  static void downloadTextFile({
    required String content,
    required String fileName,
    String mimeType = 'text/csv;charset=utf-8;',
  }) {}
}
