import 'package:bitirme_projesi/features/history/domain/entities/history_entry.dart';

class HistoryEntryModel extends HistoryEntry {
  const HistoryEntryModel({
    required super.id,
    required super.originalText,
    required super.translatedText,
    required super.createdAt,
    super.culturalContext,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return HistoryEntryModel(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      culturalContext: json['culturalContext'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMs'] as int,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'culturalContext': culturalContext,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
    };
  }

  factory HistoryEntryModel.fromEntity(HistoryEntry entry) {
    return HistoryEntryModel(
      id: entry.id,
      originalText: entry.originalText,
      translatedText: entry.translatedText,
      culturalContext: entry.culturalContext,
      createdAt: entry.createdAt,
    );
  }
}
