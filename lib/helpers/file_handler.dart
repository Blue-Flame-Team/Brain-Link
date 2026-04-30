import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class FileHandler {
  static Future<void> openFile(
    String fileUrl, {
    String? defaultFileName,
  }) async {
    if (fileUrl.startsWith('rtdb://')) {
      try {
        final path = fileUrl.replaceAll('rtdb://', '');
        final snapshot = await FirebaseDatabase.instance.ref(path).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final base64Str = data['data'] as String;
          final fileName = data['name'] as String? ?? defaultFileName ?? 'file';

          final bytes = base64Decode(base64Str);

          if (kIsWeb) {
            final uri = Uri.dataFromBytes(bytes).toString();
            await launchUrl(Uri.parse(uri));
          } else {
            final tempDir = await getTemporaryDirectory();
            final file = await File(
              '${tempDir.path}/$fileName',
            ).writeAsBytes(bytes);
            await OpenFilex.open(file.path);
          }
        }
      } catch (e) {
        debugPrint('Error opening rtdb file: $e');
      }
    } else {
      await launchUrl(Uri.parse(fileUrl));
    }
  }
}
