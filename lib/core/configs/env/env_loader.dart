import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvLoader {
  EnvLoader._();

  static Future<void> load() async {
    // Dev ortamında proje kökünde `.env` dosyası beklenir.
    // Dosya yoksa mock akışları çalışmaya devam eder.
    try {
      await dotenv.load(fileName: '.env');
      final hasDeepl = (dotenv.env['DEEPL_API_KEY'] ?? '').isNotEmpty;
      final hasLlm = (dotenv.env['LLM_API_KEY'] ?? '').isNotEmpty;
      // Sırları yazmadan var/yok bilgisini konsola basıyoruz.
      // OCR/çeviri mock modunun tetiklenip tetiklenmediğini görmek için faydalı.
      // ignore: avoid_print
      print('ENV LOADED: DEEPL_API_KEY=$hasDeepl LLM_API_KEY=$hasLlm');
    } catch (_) {
      // Anahtarlar bulunamazsa servisler mock moda düşer.
      // ignore: avoid_print
      print('ENV LOAD FAILED: .env okunamadı, mock mod kullanılacak.');
    }
  }
}

