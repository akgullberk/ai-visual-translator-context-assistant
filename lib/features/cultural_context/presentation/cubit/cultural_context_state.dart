enum CulturalContextStatus {
  initial,
  loading,
  success,
  failure,
}

class CulturalContextState {
  const CulturalContextState({
    this.status = CulturalContextStatus.initial,
    this.value = '',
    this.errorMessage,
  });

  final CulturalContextStatus status;
  final String value;
  final String? errorMessage;

  bool get isLoading => status == CulturalContextStatus.loading;

  CulturalContextState copyWith({
    CulturalContextStatus? status,
    String? value,
    String? errorMessage,
  }) {
    return CulturalContextState(
      status: status ?? this.status,
      value: value ?? this.value,
      errorMessage: errorMessage,
    );
  }
}

