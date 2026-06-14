import 'dart:convert';

import 'package:bitirme_projesi/features/history/data/models/history_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class HistoryLocalDataSource {
  Future<List<HistoryEntryModel>> getEntries();

  Future<HistoryEntryModel> saveEntry(HistoryEntryModel entry);
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(this._prefs);

  static const _storageKey = 'history_entries_v1';

  final SharedPreferences _prefs;

  @override
  Future<List<HistoryEntryModel>> getEntries() async {
    final raw = _prefs.getStringList(_storageKey) ?? const [];
    final entries = raw
        .map((item) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            return HistoryEntryModel.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<HistoryEntryModel>()
        .toList();

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<HistoryEntryModel> saveEntry(HistoryEntryModel entry) async {
    final entries = await getEntries();
    final updated = [entry, ...entries].take(200).toList();
    await _prefs.setStringList(
      _storageKey,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
    return entry;
  }
}
