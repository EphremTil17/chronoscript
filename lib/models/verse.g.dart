// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Verse _$VerseFromJson(Map<String, dynamic> json) => Verse(
  id: json['id'] as String,
  words: (json['words'] as List<dynamic>)
      .map((e) => SyncWord.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VerseToJson(Verse instance) => <String, dynamic>{
  'id': instance.id,
  'words': instance.words,
};
