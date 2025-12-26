import 'package:json_annotation/json_annotation.dart';
import 'package:chronoscript/models/sync_word.dart';

part 'verse.g.dart';

@JsonSerializable()
class Verse {
  final String id;
  final List<SyncWord> words;

  // Helpers
  bool get isFullySynced => words.every((w) => w.isSynced);
  int get syncedWordCount => words.where((w) => w.isSynced).length;

  const Verse({required this.id, required this.words});

  Verse copyWith({String? id, List<SyncWord>? words}) {
    return Verse(id: id ?? this.id, words: words ?? this.words);
  }

  factory Verse.fromJson(Map<String, dynamic> json) => _$VerseFromJson(json);
  Map<String, dynamic> toJson() => _$VerseToJson(this);
}
