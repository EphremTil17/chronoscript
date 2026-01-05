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

  /// Generates the sync.json content (Production "Clean Export")
  static String generateSyncJson(
    List<Verse> verses, {
    String? audioFileName,
    String? textFileName,
  }) {
    final Map<String, dynamic> syncData = {};

    for (var verse in verses) {
      for (var word in verse.words) {
        if (word.startTime != null && word.endTime != null) {
          syncData[word.id] = {'start': word.startTime, 'end': word.endTime};
        }
      }
    }

    // Output a lean, production-ready map
    final Map<String, dynamic> output = {
      'metadata': {
        'generator': 'ChronoScript Studio v2.4.0',
        'exported_at': DateTime.now().toIso8601String(),
        'text_source': textFileName ?? 'text_gz.md',
      },
      'sync_data': syncData,
    };

    return const JsonEncoder.withIndent('  ').convert(output);
  }

  /// Generates the full project state JSON (StudioSession)
  static String generateProjectJson({
    required List<Verse> verses,
    required String? audioFilePath,
    required String? textFilePath,
    required int selectedVerseIndex,
    required TappingTab currentTab,
  }) {
    final List<Map<String, dynamic>> versesData = verses
        .map((v) => v.toJson())
        .toList();

    final Map<String, dynamic> output = {
      'metadata': _createMetadata(
        audioFilePath: audioFilePath,
        textFilePath: textFilePath,
      ),
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
    String? textFilePath,
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
      'text_file_path': textFilePath ?? 'unknown',
      'last_modified': DateTime.now().toIso8601String(),
      'generator': 'ChronoScript Studio v2.4.0',
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
    List<Verse> verses, {
    String? baseFileName,
  }) async {
    final base = (baseFileName != null && baseFileName != 'unknown')
        ? baseFileName
        : 'project';

    final exportName = '${base}_synced_export';
    final mdName = '$exportName.md';
    final jsonName = '$exportName.json';

    final taggedMd = generateTaggedMarkdown(verses);
    final syncJson = generateSyncJson(verses, textFileName: mdName);

    final mdFile = File('$directoryPath/$mdName');
    final jsonFile = File('$directoryPath/$jsonName');

    await mdFile.writeAsString(taggedMd);
    await jsonFile.writeAsString(syncJson);
  }

  /// Saves the full project state to a custom location
  static Future<void> saveProject({
    required String filePath,
    required List<Verse> verses,
    required String? audioPath,
    required String? textPath,
    required int selectedVerseIndex,
    required TappingTab currentTab,
  }) async {
    final jsonContent = generateProjectJson(
      verses: verses,
      audioFilePath: audioPath,
      textFilePath: textPath,
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
    required String? textPath,
    required int selectedVerseIndex,
    required TappingTab currentTab,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/chrono_autosave.json');
      final projectJson = generateProjectJson(
        verses: verses,
        audioFilePath: audioPath,
        textFilePath: textPath,
        selectedVerseIndex: selectedVerseIndex,
        currentTab: currentTab,
      );
      await file.writeAsString(projectJson);
    } catch (e) {
      // Silent fail for auto-save
    }
  }
}
