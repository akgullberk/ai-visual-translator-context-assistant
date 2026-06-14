import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:bitirme_projesi/features/text_recognition/data/mappers/camera_image_mapper.dart';
import 'package:bitirme_projesi/features/text_recognition/data/models/recognized_text_model.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/live_recognition_frame.dart';

abstract class TextRecognitionDataSource {
  Future<RecognizedTextModel> recognizeText(String imagePath);

  Future<RecognizedTextModel> recognizeLiveFrame(LiveRecognitionFrame frame);
}

class TextRecognitionDataSourceImpl implements TextRecognitionDataSource {
  TextRecognitionDataSourceImpl(this._textRecognizer);

  final TextRecognizer _textRecognizer;

  @override
  Future<RecognizedTextModel> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return _processInputImage(inputImage);
  }

  @override
  Future<RecognizedTextModel> recognizeLiveFrame(LiveRecognitionFrame frame) async {
    final inputImage = CameraImageMapper.toInputImage(frame);
    return _processInputImage(inputImage);
  }

  Future<RecognizedTextModel> _processInputImage(InputImage inputImage) async {
    final result = await _textRecognizer.processImage(inputImage);
    final items = <RecognizedTextItemModel>[];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();
        if (lineText.isEmpty) {
          continue;
        }

        final box = line.boundingBox;
        items.add(
          RecognizedTextItemModel(
            value: lineText,
            left: box.left,
            top: box.top,
            right: box.right,
            bottom: box.bottom,
          ),
        );
      }
    }

    return RecognizedTextModel(
      value: result.text,
      items: items,
    );
  }
}
