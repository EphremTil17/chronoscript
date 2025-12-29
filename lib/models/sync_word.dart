import 'package:json_annotation/json_annotation.dart';

part 'sync_word.g.dart';

@JsonSerializable()
class SyncWord {
  // Unique identifier (w1, w2, etc.)
  final String id;

  // The actual text content
  final String text;

  // Start time in milliseconds (null if not yet synced)
  final int? startTime;

  // End time in milliseconds (null if not yet synced)
  final int? endTime;

  // Whether this word starts a new paragraph (visual grouping)
  final bool isParagraphStart;

  // Helper to check if synced
  bool get isSynced => startTime != null && endTime != null;

  const SyncWord({
    required this.id,
    required this.text,
    this.startTime,
    this.endTime,
    this.isParagraphStart = false,
  });

  // Create a copy with updated fields
  SyncWord copyWith({
    String? id,
    String? text,
    Object? startTime = _sentinel,
    Object? endTime = _sentinel,
    bool? isParagraphStart,
  }) {
    return SyncWord(
      id: id ?? this.id,
      text: text ?? this.text,
      startTime: startTime == _sentinel ? this.startTime : startTime as int?,
      endTime: endTime == _sentinel ? this.endTime : endTime as int?,
      isParagraphStart: isParagraphStart ?? this.isParagraphStart,
    );
  }

  static const _sentinel = Object();

  factory SyncWord.fromJson(Map<String, dynamic> json) =>
      _$SyncWordFromJson(json);
  Map<String, dynamic> toJson() => _$SyncWordToJson(this);

  @override
  String toString() =>
      'SyncWord(id: $id, text: $text, start: $startTime, end: $endTime)';
}
