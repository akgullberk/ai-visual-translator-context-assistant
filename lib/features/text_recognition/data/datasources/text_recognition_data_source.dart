import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:bitirme_projesi/features/text_recognition/data/models/recognized_text_model.dart';

abstract class TextRecognitionDataSource {
  Future<RecognizedTextModel> recognizeText(String imagePath);
}

class TextRecognitionDataSourceImpl implements TextRecognitionDataSource {
  TextRecognitionDataSourceImpl(this._textRecognizer);

  final TextRecognizer _textRecognizer;

  @override
  Future<RecognizedTextModel> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
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
