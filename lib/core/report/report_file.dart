import 'dart:typed_data';

import 'report_file_stub.dart' if (dart.library.js_interop) 'report_file_web.dart' as impl;

/// Saves a report's PDF on the person's device under [fileName], the report number
/// ("WSE-2026-11-00417.pdf", Timi 2026-11-22). In the browser it is downloaded.
void savePdf(Uint8List pdf, String fileName) => impl.savePdf(pdf, fileName);

/// The file name of a report: its number.
String reportFileName(String reportNumber) => '$reportNumber.pdf';
