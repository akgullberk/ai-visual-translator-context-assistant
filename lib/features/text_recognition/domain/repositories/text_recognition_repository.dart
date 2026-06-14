import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/live_recognition_frame.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';

abstract class TextRecognitionRepository {
  Future<Result<RecognizedTextEntity>> recognizeText(String imagePath);

  Future<Result<RecognizedTextEntity>> recognizeLiveFrame(
    LiveRecognitionFrame frame,
  );
}
