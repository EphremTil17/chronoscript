import 'package:flutter_test/flutter_test.dart';
import 'package:chronoscript/services/ingestion_service.dart';

void main() {
  group('IngestionService', () {
    test('Splits simple text by spaces', () {
      const input = "Word1 Word2 Word3";
      final words = IngestionService.parseContent(input);

      expect(words.length, 3);
      expect(words[0].text, "Word1");
      expect(words[0].id, "w1");
      expect(words[1].text, "Word2");
      expect(words[2].text, "Word3");
    });

    test('Handles newlines and multiple spaces', () {
      const input = "Word1   Word2\nWord3";
      final words = IngestionService.parseContent(input);

      expect(words.length, 3);
      expect(words[1].text, "Word2");
      expect(words[2].text, "Word3");
    });

    test('Paragraph start flag is set correctly', () {
      const input = "Line1Word1 Line1Word2\nLine2Word1";
      final words = IngestionService.parseContent(input);

      expect(words[0].isParagraphStart, true);
      expect(words[1].isParagraphStart, false);
      expect(words[2].isParagraphStart, true);
    });

    test('Handles Ge\'ez characters', () {
      const input = "ይትባረክ እግዚአብሔር";
      final words = IngestionService.parseContent(input);

      expect(words.length, 2);
      expect(words[0].text, "ይትባረክ");
      expect(words[1].text, "እግዚአብሔር");
    });
  });
}
