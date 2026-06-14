import 'dart:io';

import 'package:camera/camera.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/live_recognition_frame.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraImageMapper {
  static const _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static LiveRecognitionFrame? toLiveFrame(
    CameraImage image,
    CameraDescription camera, {
    DeviceOrientation deviceOrientation = DeviceOrientation.portraitUp,
  }) {
    if (image.planes.isEmpty) return null;

    final rotationDegrees = _computeRotationDegrees(camera, deviceOrientation);
    final inputFormat = _resolveInputFormat(image);
    if (inputFormat == null) return null;

    if (Platform.isAndroid) {
      final Uint8List? bytes;
      if (inputFormat == InputImageFormat.yuv_420_888) {
        bytes = _yuv420888ToNv21(image);
      } else if (inputFormat == InputImageFormat.nv21) {
        bytes = _nv21Bytes(image);
      } else {
        bytes = _concatenatePlanes(image.planes);
      }
      if (bytes == null) return null;

      return LiveRecognitionFrame(
        bytes: bytes,
        width: image.width,
        height: image.height,
        rotationDegrees: rotationDegrees,
        format: 'nv21',
        bytesPerRow: image.width,
      );
    }

    if (Platform.isIOS) {
      final formatKey = inputFormat == InputImageFormat.yuv420
          ? 'yuv420'
          : 'bgra8888';
      return LiveRecognitionFrame(
        bytes: image.planes.first.bytes,
        width: image.width,
        height: image.height,
        rotationDegrees: rotationDegrees,
        format: formatKey,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
    }

    return null;
  }

  static InputImage toInputImage(LiveRecognitionFrame frame) {
    return InputImage.fromBytes(
      bytes: frame.bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: _degreesToRotation(frame.rotationDegrees),
        format: _parseFormat(frame.format),
        bytesPerRow: frame.bytesPerRow,
      ),
    );
  }

  static InputImageFormat? _resolveInputFormat(CameraImage image) {
    final raw = image.format.raw;
    if (raw is! int) return null;

    final format = InputImageFormatValue.fromRawValue(raw);
    if (format == null) return null;

    if (Platform.isAndroid) {
      switch (format) {
        case InputImageFormat.nv21:
        case InputImageFormat.yuv_420_888:
        case InputImageFormat.yv12:
          return format;
        default:
          return null;
      }
    }

    if (Platform.isIOS) {
      if (format == InputImageFormat.bgra8888 ||
          format == InputImageFormat.yuv420) {
        return format;
      }
    }

    return null;
  }

  static InputImageFormat _parseFormat(String key) {
    switch (key) {
      case 'nv21':
        return InputImageFormat.nv21;
      case 'yuv420':
        return InputImageFormat.yuv420;
      default:
        return InputImageFormat.bgra8888;
    }
  }

  static int rotationDegreesForCamera(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) =>
      _computeRotationDegrees(camera, deviceOrientation);

  static int _computeRotationDegrees(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final compensation = _orientationDegrees[deviceOrientation] ?? 0;
    if (Platform.isIOS) {
      return (camera.sensorOrientation + compensation) % 360;
    }
    return (camera.sensorOrientation - compensation + 360) % 360;
  }

  static InputImageRotation _degreesToRotation(int degrees) {
    switch (degrees) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Android [ImageFormat.YUV_420_888] → ML Kit NV21.
  static Uint8List? _yuv420888ToNv21(CameraImage image) {
    if (image.planes.length < 3) return null;

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + (width * height ~/ 2));
    var idY = 0;
    var idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < height; y++) {
      final rowStart = y * yPlane.bytesPerRow;
      nv21.setRange(idY, idY + width, yPlane.bytes, rowStart);
      idY += width;
    }

    for (var y = 0; y < uvHeight; y++) {
      for (var x = 0; x < uvWidth; x++) {
        final bufferIndex = y * uvRowStride + x * uvPixelStride;
        if (bufferIndex >= vPlane.bytes.length ||
            bufferIndex >= uPlane.bytes.length) {
          return null;
        }
        nv21[idUV++] = vPlane.bytes[bufferIndex];
        nv21[idUV++] = uPlane.bytes[bufferIndex];
      }
    }

    return nv21;
  }

  static Uint8List? _nv21Bytes(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }
    return _concatenatePlanes(image.planes);
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final total = planes.fold<int>(0, (sum, p) => sum + p.bytes.length);
    final buffer = Uint8List(total);
    var offset = 0;
    for (final plane in planes) {
      buffer.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return buffer;
  }
}
