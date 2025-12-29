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

    final sortedKeys = syncData.keys.toList()..sort();

    final Map<String, dynamic> sortedSyncData = {};
    for (var key in sortedKeys) {
      sortedSyncData[key] = syncData[key];
    }

    final Map<String, dynamic> output = {
      'metadata': _createMetadata(audioFileName: audioFileName),
      'sync_data': sortedSyncData,
      'annotations': {},
    };

    return const JsonEncoder.withIndent('  ').convert(output);
  }

  /// Generates the full project state JSON (StudioSession)
  static String generateProjectJson(List<Verse> verses, String? audioFilePath) {
    final List<Map<String, dynamic>> versesData = verses
        .map((v) => v.toJson())
        .toList();

    final Map<String, dynamic> output = {
      'metadata': _createMetadata(audioFilePath: audioFilePath),
      'verses': versesData,
    };

    return const JsonEncoder.withIndent('  ').convert(output);
  }

  static Map<String, String> _createMetadata({
    String? audioFileName,
    String? audioFilePath,
  }) {
    return {
      'audio_file': audioFileName ?? 'unknown',
      'audio_file_path': audioFilePath ?? 'unknown',
      'last_modified': DateTime.now().toIso8601String(),
      'generator': 'ChronoScript Studio v2.0.0',
    };
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

  /// Saves the full project state to a custom location
  static Future<void> saveProject(
    String filePath,
    List<Verse> verses,
    String? audioPath,
  ) async {
    final jsonContent = generateProjectJson(verses, audioPath);
    final file = File(filePath);
    await file.writeAsString(jsonContent);
  }

  /// Performs an auto-save to the temporary directory
  static Future<void> saveAutoSave(
    List<Verse> verses,
    String? audioPath,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/chrono_autosave.json');
      final projectJson = generateProjectJson(verses, audioPath);
      await file.writeAsString(projectJson);
    } catch (e) {
      // Silent fail for auto-save
    }
  }
}
