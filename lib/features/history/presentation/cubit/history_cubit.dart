import 'package:bitirme_projesi/features/history/domain/usecases/get_history_entries_usecase.dart';
import 'package:bitirme_projesi/features/history/presentation/cubit/history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._getHistoryEntriesUseCase) : super(const HistoryState());

  final GetHistoryEntriesUseCase _getHistoryEntriesUseCase;

  Future<void> loadHistory() async {
    emit(state.copyWith(status: HistoryStatus.loading, errorMessage: null));

    final result = await _getHistoryEntriesUseCase();

    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(
        status: HistoryStatus.success,
        entries: result.data!,
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: HistoryStatus.failure,
      errorMessage: result.failure?.message ?? 'Geçmiş yüklenemedi.',
    ));
  }
}
