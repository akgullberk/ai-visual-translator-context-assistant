import 'package:bitirme_projesi/core/error/failure.dart';
import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/translation/data/datasources/translation_data_source.dart';
import 'package:bitirme_projesi/features/translation/data/models/translated_text_model.dart';
import 'package:bitirme_projesi/features/translation/domain/entities/translated_text.dart';
import 'package:bitirme_projesi/features/translation/domain/repositories/translation_repository.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  const TranslationRepositoryImpl(this._dataSource);

  final TranslationDataSource _dataSource;

  @override
  Future<Result<TranslatedTextEntity>> translate({
    required String text,
    required String targetLang,
  }) async {
    try {
      final translated = await _dataSource.translateText(
        text: text,
        targetLang: targetLang,
      );
      return Result.success(
        TranslatedTextModel(value: translated, targetLang: targetLang),
      );
    } catch (e) {
      return Result.fail(Failure('Çeviri sırasında bir hata oluştu: $e'));
    }
  }
}

