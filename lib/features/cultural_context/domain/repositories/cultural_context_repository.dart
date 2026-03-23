import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/entities/cultural_context_entity.dart';

abstract class CulturalContextRepository {
  Future<Result<CulturalContextEntity>> getCulturalContext({
    required String text,
  });
}

