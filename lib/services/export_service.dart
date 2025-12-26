import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/verse.dart';

class ExportService {
  /// Generates the text_gz.md content with `<w>` tags
  static String generateTaggedMarkdown(List<Verse> verses) {
    final StringBuffer buffer = StringBuffer();

    for (var verse in verses) {
      if (verse.id != "v0_intro") {
        buffer.write('\n## ${verse.id}\n');
      }

      for (var i = 0; i < verse.words.length; i++) {
        final word = verse.words[i];
        if (word.isParagraphStart && i > 0) {
          buffer.write('\n');
        }

        // Selective Synchronization: Only tag if fully synced
        if (word.startTime != null && word.endTime != null) {
          buffer.write('<${word.id}>${word.text}</${word.id}> ');
        } else {
          buffer.write('${word.text} ');
        }
      }
      buffer.write('\n');
    }

    return buffer.toString().trim();
  }

  /// Generates the sync.json content
  static String generateSyncJson(List<Verse> verses, {String? audioFileName}) {
    final Map<String, dynamic> syncData = {};

    for (var verse in verses) {
      for (var word in verse.words) {
        if (word.startTime != null && word.endTime != null) {
          syncData[word.id] = {'start': word.startTime, 'end': word.endTime};
        }
      }
    }

    // Sort keys naturally (v1_w1, v1_w2...)
    // Simple alphabetic sort works for standard IDs, but we might want alphanumeric strict if IDs vary.
    final sortedKeys = syncData.keys.toList()
      ..sort((a, b) {
        // basic sort
        return a.compareTo(b);
      });

    final Map<String, dynamic> sortedSyncData = {};
    for (var key in sortedKeys) {
      sortedSyncData[key] = syncData[key];
    }

    final Map<String, dynamic> output = {
      'metadata': {
        'audio_file': audioFileName ?? 'unknown',
        'last_modified': DateTime.now().toIso8601String().split('T').first,
        'generator': 'ChronoScript Studio',
      },
      'sync_data': sortedSyncData,
      'annotations': {},
    };

    return const JsonEncoder.withIndent('  ').convert(output);
  }

  /// Saves both files to a selected directory
  static Future<void> exportFiles(
    String directoryPath,
    List<Verse> verses,
  ) async {
    final taggedMd = generateTaggedMarkdown(verses);
    final syncJson = generateSyncJson(verses);

    final mdFile = File('$directoryPath/text_gz.md');
    final jsonFile = File('$directoryPath/sync.json');

    await mdFile.writeAsString(taggedMd);
    await jsonFile.writeAsString(syncJson);
  }

  /// Performs an auto-save to the temporary directory
  static Future<void> saveAutoSave(List<Verse> verses) async {
    try {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/chrono_autosave.json');
      final syncJson = generateSyncJson(verses);
      await file.writeAsString(syncJson);
      // print("Auto-saved to ${file.path}");
    } catch (e) {
      // Slient fail for auto-save or log
      // print("Auto-save failed: $e");
    }
  }
}
