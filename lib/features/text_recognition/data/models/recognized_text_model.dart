import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';

class RecognizedTextModel extends RecognizedTextEntity {
  const RecognizedTextModel({
    required super.value,
    required super.items,
  });
}

class RecognizedTextItemModel extends RecognizedTextItemEntity {
  const RecognizedTextItemModel({
    required super.value,
    required super.left,
    required super.top,
    required super.right,
    required super.bottom,
  });
}
