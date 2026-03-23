import 'dart:convert';

import 'package:bitirme_projesi/core/configs/env/gemini_env.dart';
import 'package:http/http.dart' as http;

abstract class CulturalContextDataSource {
  Future<String> getCulturalContext({required String text});
}

class CulturalContextDataSourceImpl implements CulturalContextDataSource {
  CulturalContextDataSourceImpl(this._client);

  final http.Client _client;

  @override
  Future<String> getCulturalContext({required String text}) async {
    return _getGeminiCulturalContext(text: text);
  }

  Future<String> _getGeminiCulturalContext({required String text}) async {
    final apiKey = GeminiEnv.apiKey;

    // Anahtar yoksa deterministik mock.
    if (apiKey.isEmpty) {
      final normalized = text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z]'), '');

      if (normalized == 'hello') {
        return jsonEncode({
          'cultural_context': 'Bu standart bir İngilizce selamlama sözcüğüdür.',
        });
      }
      return jsonEncode({
        'cultural_context': 'Kültürel bağlam şu an mock modda hesaplandı.',
      });
    }

    final model = GeminiEnv.model;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final prompt = '''
Metni kültürel ve dilsel kullanım açısından açıkla.

KURALLAR:
- Sadece JSON döndür.
- JSON şu şemaya sahip olmalı:
  {
    "cultural_context": "string"
  }
- Değer Türkçe olmalı.
- JSON dışı ek açıklama ekleme.

Metin: "$text"
''';

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 300,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final snippet = response.body.trim();
      throw Exception(
        'Gemini HTTP hatası: ${response.statusCode} - '
        '${snippet.length > 400 ? snippet.substring(0, 400) : snippet}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) {
      throw Exception('Gemini yanıtında candidates yok.');
    }

    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    if (parts.isEmpty) {
      throw Exception('Gemini yanıtında content.parts yok.');
    }

    final textResponse = parts.first['text'] as String?;
    if (textResponse == null) {
      throw Exception('Gemini yanıtında parts[0].text yok.');
    }

    final raw = textResponse.trim();

    // Gemini bazen JSON’u codeblock ile sarabiliyor; onu temizliyoruz.
    final fenced = RegExp(r'```(?:json)?\\s*([\\s\\S]*?)```', multiLine: true)
        .firstMatch(raw)
        ?.group(1)
        ?.trim();
    final candidateJson = fenced ?? raw;

    final jsonMatch = RegExp(r'\\{[\\s\\S]*\\}').firstMatch(candidateJson);
    final jsonText = (jsonMatch?.group(0) ?? candidateJson).trim();

    try {
      final decodedJson = jsonDecode(jsonText);
      return jsonEncode(decodedJson);
    } catch (_) {
      // Zorunluluk: JSON/String dön.
      return jsonText;
    }
  }
}

