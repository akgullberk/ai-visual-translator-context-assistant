import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/live_recognition_frame.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/repositories/text_recognition_repository.dart';

class RecognizeLiveFrameUseCase {
  const RecognizeLiveFrameUseCase(this._repository);

  final TextRecognitionRepository _repository;

  Future<Result<RecognizedTextEntity>> call(LiveRecognitionFrame frame) {
    return _repository.recognizeLiveFrame(frame);
  }
}
