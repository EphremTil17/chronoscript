import 'package:flutter_test/flutter_test.dart';
import 'package:chronoscript/services/ingestion_service.dart';

void main() {
  group('IngestionService', () {
    test('Splits simple text by spaces into default Verse', () {
      const input = "Word1 Word2 Word3";
      final verses = IngestionService.parseContent(input);

      expect(verses.length, 1);
      final words = verses[0].words;
      expect(words.length, 3);
      expect(words[0].text, "Word1");
      expect(words[0].id, "w1");
      expect(words[1].text, "Word2");
      expect(words[2].text, "Word3");
    });

    test('Handles newlines and multiple spaces within default Verse', () {
      const input = "Word1   Word2\nWord3";
      final verses = IngestionService.parseContent(input);
      final words = verses[0].words;

      expect(words.length, 3);
      expect(words[1].text, "Word2");
      expect(words[2].text, "Word3");
    });

    test('Paragraph start flag is set correctly', () {
      const input = "Line1Word1 Line1Word2\nLine2Word1";
      final verses = IngestionService.parseContent(input);
      final words = verses[0].words;

      expect(words[0].isParagraphStart, true);
      expect(words[1].isParagraphStart, false);
      expect(words[2].isParagraphStart, true);
    });

    test('Parses Verse headers correctly', () {
      const input = "## v1\nWord1 Word2\n## v2\nWord3";
      final verses = IngestionService.parseContent(input);

      expect(verses.length, 2);
      expect(verses[0].id, "v1");
      expect(verses[0].words.length, 2);
      expect(verses[1].id, "v2");
      expect(verses[1].words.length, 1);
      expect(verses[1].words[0].text, "Word3");
    });

    test('Handles content before first header', () {
      const input = "IntroWord\n## v1\nWord1";
      final verses = IngestionService.parseContent(input);

      expect(verses.length, 2);
      expect(verses[0].id, "v0_intro");
      expect(verses[0].words[0].text, "IntroWord");
      expect(verses[1].id, "v1");
    });
  });
}
