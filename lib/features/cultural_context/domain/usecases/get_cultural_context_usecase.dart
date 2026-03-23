import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/entities/cultural_context_entity.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/repositories/cultural_context_repository.dart';

class GetCulturalContextUseCase {
  const GetCulturalContextUseCase(this._repository);

  final CulturalContextRepository _repository;

  Future<Result<CulturalContextEntity>> call({
    required String text,
  }) {
    return _repository.getCulturalContext(text: text);
  }
}

