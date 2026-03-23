import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/translation/domain/entities/translated_text.dart';

abstract class TranslationRepository {
  Future<Result<TranslatedTextEntity>> translate({
    required String text,
    required String targetLang,
  });
}

