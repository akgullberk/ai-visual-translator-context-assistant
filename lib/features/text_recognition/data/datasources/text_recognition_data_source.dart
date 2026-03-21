import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class TextRecognitionDataSource {
  Future<String> recognizeText(String imagePath);
}

class TextRecognitionDataSourceImpl implements TextRecognitionDataSource {
  TextRecognitionDataSourceImpl(this._textRecognizer);

  final TextRecognizer _textRecognizer;

  @override
  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _textRecognizer.processImage(inputImage);
    return result.text;
  }
}
