import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/verse.dart';
import '../providers/app_state.dart';

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
  static String generateProjectJson({
    required List<Verse> verses,
    required String? audioFilePath,
    required int selectedVerseIndex,
    required TappingTab currentTab,
  }) {
    final List<Map<String, dynamic>> versesData = verses
        .map((v) => v.toJson())
        .toList();

    final Map<String, dynamic> output = {
      'metadata': _createMetadata(audioFilePath: audioFilePath),
      'state': {
        'selected_verse_index': selectedVerseIndex,
        'current_tab': currentTab.name,
      },
      'verses': versesData,
    };

    return const JsonEncoder.withIndent('  ').convert(output);
  }

  static Map<String, String> _createMetadata({
    String? audioFileName,
    String? audioFilePath,
  }) {
    // Determine the best name: explicit name > derived from path > unknown
    String finalName = 'unknown';
    if (audioFileName != null && audioFileName != 'unknown') {
      finalName = audioFileName;
    } else if (audioFilePath != null && audioFilePath != 'unknown') {
      finalName = p.basename(audioFilePath);
    }

    return {
      'audio_file': finalName,
      'audio_file_path': audioFilePath ?? 'unknown',
      'last_modified': DateTime.now().toIso8601String(),
      'generator': 'ChronoScript Studio v2.1.0',
    };
  }

  /// Loads the session JSON from a file
  static Future<Map<String, dynamic>> loadSession(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("Session file not found");
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
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
  static Future<void> saveProject({
    required String filePath,
    required List<Verse> verses,
    required String? audioPath,
    required int selectedVerseIndex,
    required TappingTab currentTab,
  }) async {
    final jsonContent = generateProjectJson(
      verses: verses,
      audioFilePath: audioPath,
      selectedVerseIndex: selectedVerseIndex,
      currentTab: currentTab,
    );
    final file = File(filePath);
    await file.writeAsString(jsonContent);
  }

  /// Performs an auto-save to the temporary directory
  static Future<void> saveAutoSave({
    required List<Verse> verses,
    required String? audioPath,
    required int selectedVerseIndex,
    required TappingTab currentTab,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/chrono_autosave.json');
      final projectJson = generateProjectJson(
        verses: verses,
        audioFilePath: audioPath,
        selectedVerseIndex: selectedVerseIndex,
        currentTab: currentTab,
      );
      await file.writeAsString(projectJson);
    } catch (e) {
      // Silent fail for auto-save
    }
  }
}
