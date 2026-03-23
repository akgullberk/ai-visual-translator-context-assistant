import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiEnv {
  GeminiEnv._();

  /// Gemini için anahtar.
  /// Eğer `GEMINI_API_KEY` yoksa geriye dönük uyumluluk için `LLM_API_KEY` kullanır.
  static String get apiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['LLM_API_KEY'] ?? '';

  /// Gemini model adı.
  /// Eğer `GEMINI_MODEL` yoksa geriye dönük uyumluluk için yalnızca
  /// `LLM_MODEL` Gemini ile alakalıysa kullanır (OpenAI modelini yanlışlıkla
  /// Gemini'ye yollamamak için).
  static String get model {
    final geminiModel = dotenv.env['GEMINI_MODEL'];
    if (geminiModel != null && geminiModel.trim().isNotEmpty) {
      return geminiModel.trim();
    }

    final llmModel = dotenv.env['LLM_MODEL'];
    final candidate = (llmModel ?? '').trim();
    if (candidate.startsWith('gemini')) {
      return candidate;
    }

    // Gemini 2 Flash (senin istediğin).
    return 'gemini-2.0-flash';
  }
}

