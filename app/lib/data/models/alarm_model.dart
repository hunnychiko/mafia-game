import 'dart:convert';

/// A wake-up alarm that can only be dismissed by typing a fresh English
/// word and answering a multiple-choice question about its meaning.
class AlarmModel {
  final int id;
  final int hour;
  final int minute;
  final String label;

  /// Weekdays this alarm repeats on, using [DateTime.monday]..[DateTime.sunday].
  /// Empty means it only rings once, then disables itself.
  final Set<int> repeatDays;
  final bool enabled;

  const AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.repeatDays = const {},
    this.enabled = true,
  });

  AlarmModel copyWith({
    int? hour,
    int? minute,
    String? label,
    Set<int>? repeatDays,
    bool? enabled,
  }) {
    return AlarmModel(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
    );
  }

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// The next [DateTime] this alarm should ring, strictly after [from].
  DateTime nextOccurrence({DateTime? from}) {
    final now = from ?? DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    if (repeatDays.isEmpty) {
      return candidate;
    }

    for (var i = 0; i < 8; i++) {
      if (repeatDays.contains(candidate.weekday)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? '',
      repeatDays: (json['repeatDays'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toSet(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'repeatDays': repeatDays.toList(),
      'enabled': enabled,
    };
  }

  factory AlarmModel.fromJsonString(String source) =>
      AlarmModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}
