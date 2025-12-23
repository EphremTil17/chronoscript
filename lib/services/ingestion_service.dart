import 'dart:io';
import '../models/sync_word.dart';

class IngestionService {
  /// Parses a raw text string or markdown content into a List<SyncWord>
  static List<SyncWord> parseContent(String content) {
    // 1. Normalize line endings
    content = content.replaceAll('\r\n', '\n');

    final List<SyncWord> words = [];
    int wordCount = 0;

    // Split by lines to preserve paragraph structure potential
    final lines = content.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check for markdown headers or special formatting if needed (ignoring for raw SyncWord extraction for now,
      // but keeping paragraph logic in mind).
      // For now, any new line could be considered a "block" or paragraph start for the first word.
      bool isFirstWordInLine = true;

      // Split line by spaces to get words
      // Using regex to split by whitespace but keep punctuation attached to words or separate?
      // User said "Splits text by spaces into individual word objects."
      // Let's stick to simple space splitting for Ge'ez/Amharic.
      final tokens = line.split(RegExp(r'\s+'));

      for (var token in tokens) {
        if (token.isEmpty) continue;

        wordCount++;
        words.add(
          SyncWord(
            id: 'w$wordCount',
            text: token,
            isParagraphStart:
                isFirstWordInLine, // First word of a new line gets this flag
          ),
        );

        isFirstWordInLine = false;
      }
    }

    return words;
  }

  /// ingest from file path
  static Future<List<SyncWord>> ingestFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("File not found: $path");
    }
    final content = await file.readAsString();
    return parseContent(content);
  }
}
