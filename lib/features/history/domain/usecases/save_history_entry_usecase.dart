import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/history/domain/entities/history_entry.dart';
import 'package:bitirme_projesi/features/history/domain/repositories/history_repository.dart';

class SaveHistoryEntryUseCase {
  const SaveHistoryEntryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Result<HistoryEntry>> call({
    required String originalText,
    required String translatedText,
    String? culturalContext,
  }) {
    return _repository.saveEntry(
      originalText: originalText,
      translatedText: translatedText,
      culturalContext: culturalContext,
    );
  }
}
