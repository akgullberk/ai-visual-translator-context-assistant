import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/history/domain/entities/history_entry.dart';

abstract class HistoryRepository {
  Future<Result<List<HistoryEntry>>> getEntries();

  Future<Result<HistoryEntry>> saveEntry({
    required String originalText,
    required String translatedText,
    String? culturalContext,
  });
}
