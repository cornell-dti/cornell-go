class AppDurations {
  AppDurations._();

  // Animation
  static const Duration animationShort = Duration(milliseconds: 300);
  static const Duration animationMedium = Duration(milliseconds: 500);

  // Delays
  static const Duration loadingDelay = Duration(seconds: 1);
  static const Duration apiTimeout = Duration(seconds: 5);
  static const Duration locationInterval = Duration(seconds: 10);

  // Timer feature (synced with server/src/timer/timer.service.ts)
  static const int extensionTimeSeconds = 300;
}
