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
    this.errorMessage,
  });

  final TextRecognitionStatus status;
  final String recognizedText;
  final String? errorMessage;

  bool get isRecognizing => status == TextRecognitionStatus.loading;

  TextRecognitionState copyWith({
    TextRecognitionStatus? status,
    String? recognizedText,
    String? errorMessage,
  }) {
    return TextRecognitionState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      errorMessage: errorMessage,
    );
  }
}
