// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncWord _$SyncWordFromJson(Map<String, dynamic> json) => SyncWord(
  id: json['id'] as String,
  text: json['text'] as String,
  startTime: (json['startTime'] as num?)?.toInt(),
  endTime: (json['endTime'] as num?)?.toInt(),
  isParagraphStart: json['isParagraphStart'] as bool? ?? false,
);

Map<String, dynamic> _$SyncWordToJson(SyncWord instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'isParagraphStart': instance.isParagraphStart,
};
