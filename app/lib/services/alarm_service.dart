import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/alarm_model.dart';

part 'alarm_service.g.dart';

@riverpod
Future<AlarmService> alarmService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AlarmService(prefs);
}

/// Persists [AlarmModel]s locally and schedules the native alarms that back
/// them via the `alarm` package. The alarm only stops ringing once the user
/// clears the word quiz on the ringing screen — see [handleSolved].
class AlarmService {
  AlarmService(this._prefs);

  final SharedPreferences _prefs;

  static const _alarmSoundAsset = 'assets/sounds/alarm_default.wav';

  List<AlarmModel> getAlarms() {
    final raw = _prefs.getStringList(AppConstants.keyWordAlarms) ?? [];
    final alarms = raw
        .map((s) {
          try {
            return AlarmModel.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<AlarmModel>()
        .toList();
    alarms.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return alarms;
  }

  AlarmModel? getById(int id) {
    for (final alarm in getAlarms()) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }

  Future<void> _saveAll(List<AlarmModel> alarms) {
    return _prefs.setStringList(
      AppConstants.keyWordAlarms,
      alarms.map((a) => a.toJsonString()).toList(),
    );
  }

  Future<void> save(AlarmModel alarm) async {
    final alarms = getAlarms().where((a) => a.id != alarm.id).toList()
      ..add(alarm);
    await _saveAll(alarms);
    if (alarm.enabled) {
      await _scheduleNative(alarm);
    } else {
      await Alarm.stop(alarm.id);
    }
  }

  Future<void> delete(int id) async {
    final alarms = getAlarms().where((a) => a.id != id).toList();
    await _saveAll(alarms);
    await Alarm.stop(id);
  }

  Future<void> setEnabled(int id, bool enabled) async {
    final alarm = getById(id);
    if (alarm == null) return;
    await save(alarm.copyWith(enabled: enabled));
  }

  Future<bool> _scheduleNative(AlarmModel alarm) {
    return Alarm.set(
      alarmSettings: AlarmSettings(
        id: alarm.id,
        dateTime: alarm.nextOccurrence(),
        assetAudioPath: _alarmSoundAsset,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        volumeSettings: const VolumeSettings.fade(
          volume: 0.9,
          fadeDuration: Duration(seconds: 5),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: '영어 단어 알람',
          body: alarm.label.isNotEmpty ? alarm.label : '영어 단어를 입력해야 알람이 꺼집니다',
        ),
      ),
    );
  }

  /// Called once the user has correctly answered the word quiz for a
  /// ringing alarm. Repeating alarms get rescheduled for their next
  /// occurrence; one-off alarms are disabled.
  Future<void> handleSolved(int id) async {
    await Alarm.stop(id);
    final alarm = getById(id);
    if (alarm == null) return;
    if (alarm.repeatDays.isEmpty) {
      await save(alarm.copyWith(enabled: false));
    } else {
      await _scheduleNative(alarm);
    }
  }

  /// Fires whenever a scheduled alarm starts ringing.
  Stream<AlarmSettings> get onRing => Alarm.ringing.expand((set) => set.alarms);

  static int generateId() =>
      DateTime.now().millisecondsSinceEpoch.remainder(1000000000);
}
