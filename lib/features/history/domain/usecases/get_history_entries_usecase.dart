import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/history/domain/entities/history_entry.dart';
import 'package:bitirme_projesi/features/history/domain/repositories/history_repository.dart';

class GetHistoryEntriesUseCase {
  const GetHistoryEntriesUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Result<List<HistoryEntry>>> call() {
    return _repository.getEntries();
  }
}
