enum TranslationStatus {
  initial,
  loading,
  success,
  failure,
}

class TranslationState {
  const TranslationState({
    this.status = TranslationStatus.initial,
    this.translatedText = '',
    this.errorMessage,
  });

  final TranslationStatus status;
  final String translatedText;
  final String? errorMessage;

  bool get isTranslating => status == TranslationStatus.loading;

  TranslationState copyWith({
    TranslationStatus? status,
    String? translatedText,
    String? errorMessage,
  }) {
    return TranslationState(
      status: status ?? this.status,
      translatedText: translatedText ?? this.translatedText,
      errorMessage: errorMessage,
    );
  }
}

