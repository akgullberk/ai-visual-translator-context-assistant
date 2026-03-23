import 'package:bitirme_projesi/features/translation/domain/usecases/translate_text_usecase.dart';
import 'package:bitirme_projesi/features/translation/presentation/cubit/translation_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit(this._translateTextUseCase) : super(const TranslationState());

  final TranslateTextUseCase _translateTextUseCase;

  Future<void> translateText({
    required String text,
    required String targetLang,
  }) async {
    emit(state.copyWith(status: TranslationStatus.loading));

    final result = await _translateTextUseCase(
      text: text,
      targetLang: targetLang,
    );

    if (result.isSuccess && result.data != null) {
      final translation = result.data!.value;
      debugPrint('TRANSLATION RESULT: $translation');
      emit(state.copyWith(
        status: TranslationStatus.success,
        translatedText: translation,
        errorMessage: null,
      ));
      return;
    }

    final error = result.failure?.message ?? 'Çeviri sırasında hata oluştu.';
    debugPrint('TRANSLATION ERROR: $error');
    emit(state.copyWith(
      status: TranslationStatus.failure,
      errorMessage: error,
    ));
  }
}

