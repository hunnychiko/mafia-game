import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

part 'word_history_service.g.dart';

@riverpod
Future<WordHistoryService> wordHistoryService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return WordHistoryService(prefs);
}

/// Tracks which English words have already been used to dismiss an alarm,
/// so the same word can't be reused within [AppConstants.wordDedupeWindowDays].
class WordHistoryService {
  WordHistoryService(this._prefs);

  final SharedPreferences _prefs;

  Map<String, int> _readHistory() {
    final raw = _prefs.getString(AppConstants.keyWordAlarmHistory);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> _writeHistory(Map<String, int> history) {
    return _prefs.setString(
        AppConstants.keyWordAlarmHistory, jsonEncode(history));
  }

  /// Removes entries older than the dedupe window so the history doesn't
  /// grow forever.
  Map<String, int> _pruned(Map<String, int> history) {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: AppConstants.wordDedupeWindowDays))
        .millisecondsSinceEpoch;
    return {
      for (final entry in history.entries)
        if (entry.value >= cutoff) entry.key: entry.value,
    };
  }

  /// Whether [word] was already used within the dedupe window.
  bool isDuplicate(String word) {
    final history = _pruned(_readHistory());
    return history.containsKey(word.trim().toLowerCase());
  }

  Future<void> recordUsage(String word) async {
    final history = _pruned(_readHistory());
    history[word.trim().toLowerCase()] = DateTime.now().millisecondsSinceEpoch;
    await _writeHistory(history);
  }
}
