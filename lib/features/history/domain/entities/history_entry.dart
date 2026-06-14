class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.createdAt,
    this.culturalContext,
  });

  final String id;
  final String originalText;
  final String translatedText;
  final String? culturalContext;
  final DateTime createdAt;
}
