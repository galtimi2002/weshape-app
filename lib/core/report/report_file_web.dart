import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Downloads the PDF under [fileName]: a link with the download attribute, clicked and removed.
void savePdf(Uint8List pdf, String fileName) {
  final url = web.URL.createObjectURL(
      web.Blob(<web.BlobPart>[pdf.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf')));
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(link);
  link.click();
  link.remove();
  // Let the download start before the address is given back.
  Future<void>.delayed(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
