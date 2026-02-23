import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

/// Android notification channel for CornellGO
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'cornellgo_notifications',
  'CornellGO Notifications',
  description: 'Notifications from CornellGO',
  importance: Importance.high,
);

/// NotificationService handles Firebase Cloud Messaging (FCM) setup and token management.
///
/// This service is responsible for:
/// - Requesting notification permissions from the user
/// - Retrieving and managing FCM tokens
/// - Setting up foreground and background message handlers
/// - Showing Android foreground notifications via flutter_local_notifications
/// - Navigating to home on notification tap
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  Function(String)? _onTokenRefresh;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  ///
  /// [onTokenRefresh] callback is called whenever the FCM token changes
  /// [navigatorKey] is used to navigate when a notification is tapped
  Future<void> initialize({
    Function(String)? onTokenRefresh,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _onTokenRefresh = onTokenRefresh;
    _navigatorKey = navigatorKey;

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications for Android foreground display
    await _initLocalNotifications();

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

  /// Initialize flutter_local_notifications for Android foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // User tapped on a local notification — navigate to home
        _navigateToHome();
      },
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
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
      _showForegroundNotification(message);
    }
  }

  /// Handle notification tap when app was in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification opened app: ${message.messageId}');
    _navigateToHome();
  }

  /// Show a notification when app is in foreground
  void _showForegroundNotification(RemoteMessage message) async {
    if (Platform.isIOS) {
      // iOS shows foreground notifications natively with these options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // Android requires manual display via flutter_local_notifications
      final notification = message.notification;
      if (notification == null) return;

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
      );
    }
  }

  /// Navigate to the home page
  void _navigateToHome() {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil('/home', (route) => false);
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
