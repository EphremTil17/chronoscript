import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/sync_word.dart';

class ExportService {
  /// Generates the text_gz.md content with <w> tags
  static String generateTaggedMarkdown(List<SyncWord> words) {
    final StringBuffer buffer = StringBuffer();

    // We attempt to reconstruct structure based on isParagraphStart
    for (var i = 0; i < words.length; i++) {
      final word = words[i];

      if (word.isParagraphStart && i > 0) {
        buffer.write('\n');
      }

      // Wrap word in tag
      buffer.write('<${word.id}>${word.text}</${word.id}> ');
    }

    return buffer.toString().trim();
  }

  /// Generates the sync.json content
  static String generateSyncJson(List<SyncWord> words) {
    final Map<String, dynamic> syncData = {};

    for (var word in words) {
      if (word.startTime != null && word.endTime != null) {
        syncData[word.id] = {'start': word.startTime, 'end': word.endTime};
      }
    }

    final Map<String, dynamic> output = {
      'sync_data': syncData,
      'annotations': {}, // Future expansion
    };

    return const JsonEncoder.withIndent('  ').convert(output);
  }

  /// Saves both files to a selected directory
  static Future<void> exportFiles(
    String directoryPath,
    List<SyncWord> words,
  ) async {
    final taggedMd = generateTaggedMarkdown(words);
    final syncJson = generateSyncJson(words);

    final mdFile = File('$directoryPath/text_gz.md');
    final jsonFile = File('$directoryPath/sync.json');

    await mdFile.writeAsString(taggedMd);
    await jsonFile.writeAsString(syncJson);
  }

  /// Performs an auto-save to the temporary directory
  static Future<void> saveAutoSave(List<SyncWord> words) async {
    try {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/chrono_autosave.json');
      final syncJson = generateSyncJson(words);
      await file.writeAsString(syncJson);
      // print("Auto-saved to ${file.path}");
    } catch (e) {
      // Slient fail for auto-save or log
      // print("Auto-save failed: $e");
    }
  }
}
