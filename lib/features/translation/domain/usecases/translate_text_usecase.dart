import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/translation/domain/entities/translated_text.dart';
import 'package:bitirme_projesi/features/translation/domain/repositories/translation_repository.dart';

class TranslateTextUseCase {
  const TranslateTextUseCase(this._repository);

  final TranslationRepository _repository;

  Future<Result<TranslatedTextEntity>> call({
    required String text,
    required String targetLang,
  }) {
    return _repository.translate(text: text, targetLang: targetLang);
  }
}

