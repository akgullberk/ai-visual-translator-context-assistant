import 'package:flutter_dotenv/flutter_dotenv.dart';

class LlmEnv {
  LlmEnv._();

  static String get apiKey => dotenv.env['LLM_API_KEY'] ?? '';

  static String get baseUrl =>
      dotenv.env['LLM_BASE_URL'] ?? 'https://api.openai.com';

  static String get model => dotenv.env['LLM_MODEL'] ?? 'gpt-4o-mini';
}

