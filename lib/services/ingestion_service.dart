import 'dart:io';
import '../models/sync_word.dart';
import '../models/verse.dart';

class IngestionService {
  /// Parses a raw text string or markdown content into a list of Verses
  static List<Verse> parseContent(String content) {
    content = content.replaceAll('\r\n', '\n');
    final headerRegex = RegExp(r'(^|\n)##\s+(.*?)(?=\n|$)');

    List<Verse> verses = [];
    int wordGlobalIndex = 0;

    // Find all matches
    final matches = headerRegex.allMatches(content).toList();

    // 1. Handle Case: No Headers found
    if (matches.isEmpty) {
      final words = _parseWords(content, wordGlobalIndex);
      if (words.isNotEmpty) {
        verses.add(Verse(id: "v1", words: words));
      }
      return verses;
    }

    // 2. Handle Content Before First Header
    if (matches.first.start > 0) {
      final preHeaderContent = content.substring(0, matches.first.start);
      final words = _parseWords(preHeaderContent, wordGlobalIndex);
      wordGlobalIndex += words.length;
      if (words.isNotEmpty) {
        verses.add(Verse(id: "v0_intro", words: words));
      }
    }

    // 3. Handle Header Blocks
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final header = match.group(2)?.trim() ?? "v${i + 1}";

      final startOfBody = match.end;
      final endOfBody = (i < matches.length - 1)
          ? matches[i + 1].start
          : content.length;

      final body = content.substring(startOfBody, endOfBody);
      final words = _parseWords(body, wordGlobalIndex);
      wordGlobalIndex += words.length;

      if (words.isNotEmpty) {
        verses.add(Verse(id: header, words: words));
      }
    }

    return verses;
  }

  static List<SyncWord> _parseWords(String text, int startIndex) {
    List<SyncWord> words = [];
    int idx = startIndex;
    final lines = text.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      bool isPara = true;
      final tokens = line.split(RegExp(r'\s+'));
      for (var token in tokens) {
        if (token.isEmpty) continue;
        idx++;
        words.add(SyncWord(id: 'w$idx', text: token, isParagraphStart: isPara));
        isPara = false;
      }
    }
    return words;
  }

  /// ingest from file path
  static Future<List<Verse>> ingestFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("File not found: $path");
    }
    final content = await file.readAsString();
    return parseContent(content);
  }
}
