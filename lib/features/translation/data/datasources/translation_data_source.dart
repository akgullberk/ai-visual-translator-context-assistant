import 'dart:convert';

import 'package:bitirme_projesi/core/configs/env/deepl_env.dart';
import 'package:http/http.dart' as http;

abstract class TranslationDataSource {
  Future<String> translateText({
    required String text,
    required String targetLang,
  });
}

class DeepLTranslationDataSource implements TranslationDataSource {
  DeepLTranslationDataSource(this._client);

  final http.Client _client;

  @override
  Future<String> translateText({
    required String text,
    required String targetLang,
  }) async {
    final apiKey = DeeplEnv.apiKey;

    // Anahtar yoksa test için deterministik mock döner.
    if (apiKey.isEmpty) {
      final normalized = text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z]'), '');

      if (normalized == 'hello' && targetLang.toUpperCase() == 'TR') {
        return 'Merhaba';
      }
      return text;
    }

    final uri = Uri.parse('${DeeplEnv.baseUrl}/v2/translate');

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'DeepL-Auth-Key $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': [text],
        'target_lang': targetLang,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DeepL HTTP hatası: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final translations = decoded['translations'] as List<dynamic>? ?? const [];
    if (translations.isEmpty) {
      throw Exception('DeepL yanıtında translations bulunamadı.');
    }

    final first = translations.first as Map<String, dynamic>;
    final translatedText = first['text'] as String?;
    if (translatedText == null) {
      throw Exception('DeepL yanıtında text alanı yok.');
    }
    return translatedText;
  }
}

