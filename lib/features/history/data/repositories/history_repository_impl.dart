import 'package:bitirme_projesi/core/error/failure.dart';
import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/history/data/datasources/history_local_data_source.dart';
import 'package:bitirme_projesi/features/history/data/models/history_entry_model.dart';
import 'package:bitirme_projesi/features/history/domain/entities/history_entry.dart';
import 'package:bitirme_projesi/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._dataSource);

  final HistoryLocalDataSource _dataSource;

  @override
  Future<Result<List<HistoryEntry>>> getEntries() async {
    try {
      final entries = await _dataSource.getEntries();
      return Result.success(entries);
    } catch (e) {
      return Result.fail(Failure('Geçmiş yüklenemedi: $e'));
    }
  }

  @override
  Future<Result<HistoryEntry>> saveEntry({
    required String originalText,
    required String translatedText,
    String? culturalContext,
  }) async {
    try {
      final entry = HistoryEntryModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalText: originalText.trim(),
        translatedText: translatedText.trim(),
        culturalContext: culturalContext?.trim(),
        createdAt: DateTime.now(),
      );
      final saved = await _dataSource.saveEntry(entry);
      return Result.success(saved);
    } catch (e) {
      return Result.fail(Failure('Geçmişe kaydedilemedi: $e'));
    }
  }
}
