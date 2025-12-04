import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print('Message notification: ${message.notification?.title}');
  }
}

/// NotificationService handles Firebase Cloud Messaging (FCM) setup and token management.
///
/// This service is responsible for:
/// - Requesting notification permissions from the user
/// - Retrieving and managing FCM tokens
/// - Setting up foreground and background message handlers
/// - Listening for token refresh events
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;
  Function(String)? _onTokenRefresh;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  ///
  /// This should be called after Firebase.initializeApp() in main.dart
  /// [onTokenRefresh] callback is called whenever the FCM token changes
  Future<void> initialize({Function(String)? onTokenRefresh}) async {
    _onTokenRefresh = onTokenRefresh;

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    await _requestPermissions();

    // Get initial FCM token
    await _getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      _onTokenRefresh?.call(newToken);
    });

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Request notification permissions from the user
  Future<bool> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
      return true;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
      return true;
    } else {
      print('User declined or has not accepted notification permission');
      return false;
    }
  }

  /// Get the FCM token for this device
  Future<String?> _getToken() async {
    try {
      // For iOS, we need to get the APNs token first
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          print('APNs token not available yet');
          // APNs token might not be immediately available on iOS
          // The token refresh listener will catch it later
        }
      }

      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        _onTokenRefresh?.call(_fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');

    if (message.notification != null) {
      print('Notification title: ${message.notification?.title}');
      print('Notification body: ${message.notification?.body}');

      // For foreground notifications, you might want to show a local notification
      // or display an in-app banner. Firebase Messaging doesn't automatically
      // show notifications when the app is in the foreground.
      _showForegroundNotification(message);
    }

    if (message.data.isNotEmpty) {
      print('Message data: ${message.data}');
      // Handle data payload
    }
  }

  /// Handle notification tap when app was in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification opened app: ${message.messageId}');
    print('Message data: ${message.data}');

    // Handle navigation based on notification data
    // For example: navigate to a specific event or challenge
    if (message.data.containsKey('eventId')) {
      // Navigate to event
      print('Should navigate to event: ${message.data['eventId']}');
    }
  }

  /// Show a notification when app is in foreground
  ///
  /// On iOS, foreground notifications are shown automatically if
  /// presentation options are set. On Android, we need to handle this manually.
  void _showForegroundNotification(RemoteMessage message) async {
    // For iOS, set foreground presentation options
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // For Android, you might want to use flutter_local_notifications
    // to show a notification manually when in foreground.
    // For now, we'll just log it since the notification will be shown
    // automatically on iOS and this is primarily for manual admin notifications.
  }

  /// Manually refresh the FCM token
  Future<String?> refreshToken() async {
    await _messaging.deleteToken();
    return await _getToken();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
