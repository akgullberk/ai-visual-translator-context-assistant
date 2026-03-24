import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';

enum TextRecognitionStatus {
  initial,
  loading,
  success,
  failure,
}

class TextRecognitionState {
  const TextRecognitionState({
    this.status = TextRecognitionStatus.initial,
    this.recognizedText = '',
    this.recognizedItems = const [],
    this.errorMessage,
  });

  final TextRecognitionStatus status;
  final String recognizedText;
  final List<RecognizedTextItemEntity> recognizedItems;
  final String? errorMessage;

  bool get isRecognizing => status == TextRecognitionStatus.loading;

  TextRecognitionState copyWith({
    TextRecognitionStatus? status,
    String? recognizedText,
    List<RecognizedTextItemEntity>? recognizedItems,
    String? errorMessage,
  }) {
    return TextRecognitionState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      recognizedItems: recognizedItems ?? this.recognizedItems,
      errorMessage: errorMessage,
    );
  }
}
