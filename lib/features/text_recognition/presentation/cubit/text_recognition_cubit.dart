import 'package:bitirme_projesi/features/text_recognition/domain/usecases/recognize_text_usecase.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TextRecognitionCubit extends Cubit<TextRecognitionState> {
  TextRecognitionCubit(this._recognizeTextUseCase)
    : super(const TextRecognitionState());

  final RecognizeTextUseCase _recognizeTextUseCase;

  Future<void> recognizeTextFromImage(String imagePath) async {
    emit(state.copyWith(status: TextRecognitionStatus.loading));

    final result = await _recognizeTextUseCase(imagePath);

    if (result.isSuccess && result.data != null) {
      final text = result.data!.value;
      debugPrint('OCR RESULT: $text');
      emit(
        state.copyWith(
          status: TextRecognitionStatus.success,
          recognizedText: text,
          errorMessage: null,
        ),
      );
      return;
    }

    final error = result.failure?.message ?? 'Bilinmeyen bir hata oluştu.';
    debugPrint('OCR ERROR: $error');
    emit(
      state.copyWith(
        status: TextRecognitionStatus.failure,
        errorMessage: error,
      ),
    );
  }
}
