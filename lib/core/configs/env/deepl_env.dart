import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeeplEnv {
  DeeplEnv._();

  static String get apiKey => dotenv.env['DEEPL_API_KEY'] ?? '';

  static String get baseUrl =>
      dotenv.env['DEEPL_BASE_URL'] ?? 'https://api-free.deepl.com';
}

