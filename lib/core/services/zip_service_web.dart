import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Save ZIP file on web platform - triggers browser download
Future<void> saveZipFile(Uint8List data, String fileName) async {
  // Create a blob from the data
  final blob = web.Blob(
    [data.toJS].toJS,
    web.BlobPropertyBag(type: 'application/zip'),
  );

  // Create object URL
  final url = web.URL.createObjectURL(blob);

  // Create and click download link
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);

  // Revoke object URL after a delay
  Future.delayed(const Duration(seconds: 1), () {
    web.URL.revokeObjectURL(url);
  });
}
