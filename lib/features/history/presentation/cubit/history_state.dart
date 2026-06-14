import 'package:bitirme_projesi/features/history/domain/entities/history_entry.dart';

enum HistoryStatus { initial, loading, success, failure }

class HistoryState {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<HistoryEntry> entries;
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryEntry>? entries,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage,
    );
  }
}
