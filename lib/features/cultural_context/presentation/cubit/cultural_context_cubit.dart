import 'package:bitirme_projesi/features/cultural_context/domain/usecases/get_cultural_context_usecase.dart';
import 'package:bitirme_projesi/features/cultural_context/presentation/cubit/cultural_context_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CulturalContextCubit extends Cubit<CulturalContextState> {
  CulturalContextCubit(this._getCulturalContextUseCase)
    : super(const CulturalContextState());

  final GetCulturalContextUseCase _getCulturalContextUseCase;

  Future<void> getCulturalContext({required String text}) async {
    emit(state.copyWith(status: CulturalContextStatus.loading));

    final result = await _getCulturalContextUseCase(text: text);

    if (result.isSuccess && result.data != null) {
      final value = result.data!.value;
      debugPrint('CULTURAL_CONTEXT RESULT: $value');
      emit(state.copyWith(
        status: CulturalContextStatus.success,
        value: value,
        errorMessage: null,
      ));
      return;
    }

    final error = result.failure?.message ?? 'Kültürel bağlam sırasında hata oluştu.';
    debugPrint('CULTURAL_CONTEXT ERROR: $error');
    emit(state.copyWith(
      status: CulturalContextStatus.failure,
      errorMessage: error,
    ));
  }
}

