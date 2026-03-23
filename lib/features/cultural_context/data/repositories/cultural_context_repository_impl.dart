import 'package:bitirme_projesi/core/error/failure.dart';
import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/cultural_context/data/datasources/cultural_context_data_source.dart';
import 'package:bitirme_projesi/features/cultural_context/data/models/cultural_context_model.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/entities/cultural_context_entity.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/repositories/cultural_context_repository.dart';

class CulturalContextRepositoryImpl implements CulturalContextRepository {
  const CulturalContextRepositoryImpl(this._dataSource);

  final CulturalContextDataSource _dataSource;

  @override
  Future<Result<CulturalContextEntity>> getCulturalContext({
    required String text,
  }) async {
    try {
      final value = await _dataSource.getCulturalContext(text: text);
      return Result.success(CulturalContextModel(value: value));
    } catch (e) {
      return Result.fail(Failure('Kültürel bağlam alınamadı: $e'));
    }
  }
}

