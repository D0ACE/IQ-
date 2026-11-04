import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

class FileDownloader {
  static void downloadTextFile({
    required String content,
    required String fileName,
    String mimeType = 'text/csv;charset=utf-8;',
  }) {
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url);
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }
}
