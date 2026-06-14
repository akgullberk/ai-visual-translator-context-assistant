import 'dart:typed_data';

/// Kamera akışından gelen tek kare (saf Dart — domain).
class LiveRecognitionFrame {
  const LiveRecognitionFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.format,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// 0, 90, 180 veya 270
  final int rotationDegrees;

  /// `nv21` (Android) veya `bgra8888` (iOS)
  final String format;
  final int bytesPerRow;
}
