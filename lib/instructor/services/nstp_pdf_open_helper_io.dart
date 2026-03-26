import 'dart:io';
import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> openPdfWithInstalledApps(Uint8List bytes, String filename) async {
  try {
    final directory = await getTemporaryDirectory();
    final safeFilename =
        filename.toLowerCase().endsWith('.pdf') ? filename : '$filename.pdf';
    final file = File('${directory.path}/$safeFilename');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFile.open(file.path, type: 'application/pdf');
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}
