import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/repositories/text_recognition_repository.dart';

class RecognizeTextUseCase {
  const RecognizeTextUseCase(this._repository);

  final TextRecognitionRepository _repository;

  Future<Result<RecognizedTextEntity>> call(String imagePath) {
    return _repository.recognizeText(imagePath);
  }
}
