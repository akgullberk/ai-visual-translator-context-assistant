import 'dart:convert';

import 'package:bitirme_projesi/core/error/failure.dart';
import 'package:bitirme_projesi/core/error/result.dart';
import 'package:bitirme_projesi/features/cultural_context/data/datasources/cultural_context_data_source.dart';
import 'package:bitirme_projesi/features/cultural_context/data/models/cultural_context_model.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/entities/cultural_context_entity.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/repositories/cultural_context_repository.dart';

class CulturalContextRepositoryImpl implements CulturalContextRepository {
  const CulturalContextRepositoryImpl(this._dataSource);

  final CulturalContextDataSource _dataSource;

  String _stripMarkdownFences(String input) {
    final raw = input.trim();
    final match = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      multiLine: true,
    ).firstMatch(raw);
    return (match?.group(1) ?? raw).trim();
  }

  String _extractLikelyJson(String input) {
    final raw = input.trim();
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    return (match?.group(0) ?? raw).trim();
  }

  String _normalizeValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final unfenced = _stripMarkdownFences(trimmed);
    final maybeJson = _extractLikelyJson(unfenced);

    // DataSource çoğunlukla JSON string döndürüyor.
    try {
      final decoded = jsonDecode(maybeJson);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['cultural_context'];
        if (value is String) {
          return value.trim();
        }
      }
    } catch (_) {
      // JSON değilse olduğu gibi kullan.
    }

    return unfenced;
  }

  @override
  Future<Result<CulturalContextEntity>> getCulturalContext({
    required String text,
  }) async {
    try {
      final raw = await _dataSource.getCulturalContext(text: text);
      final normalized = _normalizeValue(raw);
      return Result.success(CulturalContextModel(value: normalized));
    } catch (e) {
      return Result.fail(Failure('Kültürel bağlam alınamadı: $e'));
    }
  }
}

