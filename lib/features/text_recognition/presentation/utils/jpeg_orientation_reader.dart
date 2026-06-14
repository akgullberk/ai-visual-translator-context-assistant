import 'dart:typed_data';
import 'dart:ui';

/// JPEG EXIF Orientation (tag 0x0112) okuyucu.
class JpegOrientationReader {
  static int? readOrientation(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }

    var offset = 2;
    while (offset + 4 < bytes.length) {
      if (bytes[offset] != 0xFF) return null;
      final marker = bytes[offset + 1];
      if (marker == 0xDA) break;

      final segmentLength = _u16(bytes, offset + 2);
      if (segmentLength < 2) return null;

      if (marker == 0xE1 && offset + segmentLength + 1 < bytes.length) {
        final exifHeader = offset + 4;
        if (exifHeader + 6 <= bytes.length) {
          final header = String.fromCharCodes(
            bytes.sublist(exifHeader, exifHeader + 6),
          );
          if (header == 'Exif\u0000\u0000') {
            return _readOrientationFromTiff(bytes, exifHeader + 6);
          }
        }
      }

      offset += 2 + segmentLength;
    }
    return null;
  }

  static Size orientedSize(Size rawSize, int? orientation) {
    if (orientation == null) return rawSize;
    switch (orientation) {
      case 5:
      case 6:
      case 7:
      case 8:
        return Size(rawSize.height, rawSize.width);
      default:
        return rawSize;
    }
  }

  static int _u16(Uint8List data, int offset) {
    return (data[offset] << 8) | data[offset + 1];
  }

  static int _u32(Uint8List data, int offset, {required bool littleEndian}) {
    if (littleEndian) {
      return data[offset] |
          (data[offset + 1] << 8) |
          (data[offset + 2] << 16) |
          (data[offset + 3] << 24);
    }
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  static int? _readOrientationFromTiff(Uint8List data, int offset) {
    if (offset + 8 > data.length) return null;

    final byteOrder = String.fromCharCodes(data.sublist(offset, offset + 2));
    final littleEndian = byteOrder == 'II';
    if (!littleEndian && byteOrder != 'MM') return null;

    final ifdOffset = _u32(data, offset + 4, littleEndian: littleEndian);
    final ifdStart = offset + ifdOffset;
    if (ifdStart + 2 > data.length) return null;

    final entryCount = _u16(data, ifdStart);
    var entryOffset = ifdStart + 2;
    for (var i = 0; i < entryCount; i++) {
      if (entryOffset + 12 > data.length) return null;
      final tag = _u16(data, entryOffset);
      if (tag == 0x0112) {
        final value = _u16(data, entryOffset + 8);
        return value >= 1 && value <= 8 ? value : null;
      }
      entryOffset += 12;
    }
    return null;
  }
}
