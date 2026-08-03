abstract class AppConstants {
  static const String appName = 'Lullify';

  // Timer presets (minutes)
  static const List<int> timerPresets = [15, 30, 60, 90];
  static const int defaultTimerMinutes = 30;

  // Fade out options (seconds)
  static const List<int> fadeOutOptions = [0, 30, 60, 180];
  static const int defaultFadeOutSeconds = 60;

  // Sleep screen delay (seconds)
  static const List<int> sleepScreenDelays = [10, 30, 60, 0];
  static const int defaultSleepScreenDelay = 10;

  // Sound limits
  static const int maxSoundDurationSeconds = 1800; // 30분

  // AdMob
  static const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // test
  static const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716'; // test
  static const String androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // test
  static const String iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313'; // test

  // Local storage keys
  static const String keyFavorites = 'favorites';
  static const String keyRecentPlayed = 'recent_played';
  static const String keyDefaultTimer = 'default_timer';
  static const String keyDefaultFadeOut = 'default_fade_out';
  static const String keySleepScreenDelay = 'sleep_screen_delay';
  static const String keyLanguage = 'language';
  static const String keyAdRemoved = 'ad_removed';
  static const String keyUnlockedSounds = 'unlocked_sounds';
  static const String keyMixes = 'saved_mixes';
  static const String keyWordAlarms = 'word_alarms';
  static const String keyWordAlarmHistory = 'word_alarm_history';

  // Word alarm
  static const int wordDedupeWindowDays = 30;
}

abstract class SoundCategory {
  static const String noise = 'noise';
  static const String nature = 'nature';
  static const String indoor = 'indoor';
  static const String ambient = 'ambient';

  static const List<String> all = [noise, nature, indoor, ambient];
}

abstract class SoundStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String hidden = 'hidden';
}

abstract class UnlockType {
  static const String free = 'free';
  static const String premium = 'premium';
  static const String ad = 'ad';
}
