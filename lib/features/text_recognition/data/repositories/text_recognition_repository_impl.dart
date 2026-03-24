import 'package:bitirme_projesi/core/error/failure.dart';
import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/text_recognition/data/datasources/text_recognition_data_source.dart';
import 'package:bitirme_projesi/features/text_recognition/data/models/recognized_text_model.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/repositories/text_recognition_repository.dart';

class TextRecognitionRepositoryImpl implements TextRecognitionRepository {
  const TextRecognitionRepositoryImpl(this._dataSource);

  final TextRecognitionDataSource _dataSource;

  @override
  Future<Result<RecognizedTextEntity>> recognizeText(String imagePath) async {
    try {
      final text = await _dataSource.recognizeText(imagePath);
      final model = RecognizedTextModel(
        value: text.value,
        items: text.items,
      );
      return Result.success(model);
    } catch (_) {
      return Result.fail(const Failure('Metin tanıma sırasında bir hata oluştu.'));
    }
  }
}
