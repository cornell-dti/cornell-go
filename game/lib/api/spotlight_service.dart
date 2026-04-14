import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ActiveSpotlight {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  ActiveSpotlight({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory ActiveSpotlight.fromJson(Map<String, dynamic> json) {
    return ActiveSpotlight(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
    );
  }
}

/// Top-level callback invoked by the OS when a geofence is triggered.
/// Runs in a background isolate — no access to app state.
/// Always uses HTTP to call the server (works whether app is open or closed).
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint(
    'Geofence triggered: ${params.geofences.map((g) => g.id).join(", ")} '
    'event: ${params.event}',
  );

  if (params.event != GeofenceEvent.enter) return;

  try {
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'spotlight_access_token');
    if (accessToken == null) return;

    final apiUrl = await storage.read(key: 'spotlight_api_url');
    if (apiUrl == null) return;

    for (final geofence in params.geofences) {
      final body = jsonEncode({
        'spotlightId': geofence.id,
        'latitude': params.location?.latitude ?? 0,
        'longitude': params.location?.longitude ?? 0,
      });

      await http.post(
        Uri.parse('$apiUrl/spotlight/notify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );
      debugPrint('Spotlight notification requested for ${geofence.id}');
    }
  } catch (e) {
    debugPrint('Geofence HTTP request failed: $e');
  }
}

/// SpotlightService registers OS-level geofences for admin-configured
/// spotlight zones. When the user enters a zone (even with the app closed),
/// the OS triggers [geofenceTriggered], which makes an HTTP POST to the
/// server. The server handles all anti-spam logic (daily cap, cooldown,
/// time window, completion filter) and sends an FCM push if eligible.
class SpotlightService {
  static final SpotlightService _instance = SpotlightService._internal();
  factory SpotlightService() => _instance;
  SpotlightService._internal();

  List<ActiveSpotlight> _spotlights = [];
  Timer? _refreshTimer;
  io.Socket? _socket;

  /// Start the spotlight service with the connected socket.
  Future<void> start(io.Socket socket, String apiUrl) async {
    _socket = socket;

    // Store API URL and access token for the background callback
    const storage = FlutterSecureStorage();
    await storage.write(key: 'spotlight_api_url', value: apiUrl);

    // Initialize native geofence manager
    await NativeGeofenceManager.instance.initialize();

    // Fetch spotlights and register geofences
    await _fetchAndRegisterGeofences();

    // Refresh geofences every 15 minutes
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _fetchAndRegisterGeofences(),
    );
  }

  /// Stop the service (e.g., on logout)
  Future<void> stop() async {
    _refreshTimer?.cancel();
    _socket = null;
    _spotlights = [];

    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
    } catch (e) {
      debugPrint('Failed to remove geofences: $e');
    }
  }

  /// Request "Always Allow" location permission.
  Future<bool> requestAlwaysPermission() async {
    var status = await Permission.locationAlways.status;
    if (status.isGranted) return true;

    if (!(await Permission.locationWhenInUse.isGranted)) {
      final whenInUse = await Permission.locationWhenInUse.request();
      if (!whenInUse.isGranted) return false;
    }

    status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  Future<void> _fetchAndRegisterGeofences() async {
    if (_socket == null || !_socket!.connected) return;

    final hasPermission = await Permission.locationAlways.isGranted;
    if (!hasPermission) {
      debugPrint(
        'Spotlight geofences: "Always Allow" location not granted, skipping',
      );
      return;
    }

    try {
      final completer = Completer<dynamic>();
      _socket!.emitWithAck('getActiveSpotlights', {}, ack: (data) {
        completer.complete(data);
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (result is! List) return;

      final newSpotlights = result
          .map((item) =>
              ActiveSpotlight.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // Check if spotlights changed
      final newIds = newSpotlights.map((s) => s.id).toSet();
      final oldIds = _spotlights.map((s) => s.id).toSet();
      if (newIds.length == oldIds.length && newIds.containsAll(oldIds)) {
        return;
      }

      _spotlights = newSpotlights;
      debugPrint('Loaded ${_spotlights.length} active spotlights');

      // Remove old geofences and register new ones
      await NativeGeofenceManager.instance.removeAllGeofences();

      for (final spotlight in _spotlights) {
        final radius =
            spotlight.radiusMeters < 10 ? 10.0 : spotlight.radiusMeters;

        final geofence = Geofence(
          id: spotlight.id,
          location: Location(
            latitude: spotlight.latitude,
            longitude: spotlight.longitude,
          ),
          radiusMeters: radius,
          triggers: {GeofenceEvent.enter},
          iosSettings: const IosGeofenceSettings(initialTrigger: true),
          androidSettings: AndroidGeofenceSettings(
            initialTriggers: {GeofenceEvent.enter},
            expiration: const Duration(days: 90),
            loiteringDelay: const Duration(minutes: 5),
            notificationResponsiveness: const Duration(minutes: 5),
          ),
        );

        await NativeGeofenceManager.instance.createGeofence(
          geofence,
          geofenceTriggered,
        );
        debugPrint('Registered geofence for spotlight: ${spotlight.id}');
      }
    } catch (e) {
      debugPrint('Failed to fetch/register spotlight geofences: $e');
    }
  }
}
