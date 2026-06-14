import 'dart:math' as math;
import 'dart:ui';

/// ML Kit OCR kutularını ekran koordinatına taşır.
class OcrViewportMapper {
  /// Döndürme uygulandıktan sonra ML Kit'in kullandığı görüntü boyutu.
  static Size coordinateImageSize({
    required int bufferWidth,
    required int bufferHeight,
    required int rotationDegrees,
  }) {
    if (rotationDegrees == 90 || rotationDegrees == 270) {
      return Size(bufferHeight.toDouble(), bufferWidth.toDouble());
    }
    return Size(bufferWidth.toDouble(), bufferHeight.toDouble());
  }

  /// [CameraPreview] ile aynı mantık: kırpılarak ekranı doldurur (BoxFit.cover).
  static Rect coverRect({
    required Size imageSize,
    required Size viewportSize,
  }) {
    final scale = math.max(
      viewportSize.width / imageSize.width,
      viewportSize.height / imageSize.height,
    );
    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    final left = (viewportSize.width - scaledWidth) / 2;
    final top = (viewportSize.height - scaledHeight) / 2;
    return Rect.fromLTWH(left, top, scaledWidth, scaledHeight);
  }

  /// Statik görüntü önizlemesi (BoxFit.contain).
  static Rect containRect({
    required Size imageSize,
    required Size viewportSize,
  }) {
    final scale = math.min(
      viewportSize.width / imageSize.width,
      viewportSize.height / imageSize.height,
    );
    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    final left = (viewportSize.width - scaledWidth) / 2;
    final top = (viewportSize.height - scaledHeight) / 2;
    return Rect.fromLTWH(left, top, scaledWidth, scaledHeight);
  }

  static Rect mapBoundingBox({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required Size imageSize,
    required Rect displayRect,
    bool mirrorHorizontal = false,
  }) {
    var l = left;
    var r = right;
    if (mirrorHorizontal) {
      l = imageSize.width - right;
      r = imageSize.width - left;
    }

    return Rect.fromLTRB(
      displayRect.left + (l / imageSize.width) * displayRect.width,
      displayRect.top + (top / imageSize.height) * displayRect.height,
      displayRect.left + (r / imageSize.width) * displayRect.width,
      displayRect.top + (bottom / imageSize.height) * displayRect.height,
    );
  }

  /// OCR kutularının sığdığı görüntü boyutunu doğrular; gerekirse en-boy değiştirir.
  static Size fitImageSizeToOcrItems({
    required Size candidate,
    required Iterable<double> rightEdges,
    required Iterable<double> bottomEdges,
  }) {
    final maxRight = rightEdges.isEmpty
        ? 0.0
        : rightEdges.reduce(math.max);
    final maxBottom = bottomEdges.isEmpty
        ? 0.0
        : bottomEdges.reduce(math.max);
    if (maxRight <= 0 && maxBottom <= 0) return candidate;

    final swapped = Size(candidate.height, candidate.width);
    final fitsCandidate =
        maxRight <= candidate.width * 1.02 && maxBottom <= candidate.height * 1.02;
    if (fitsCandidate) return candidate;

    final fitsSwapped =
        maxRight <= swapped.width * 1.02 && maxBottom <= swapped.height * 1.02;
    if (fitsSwapped) return swapped;

    return candidate;
  }
}
