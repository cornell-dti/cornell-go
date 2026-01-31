import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  static bool didMakeRequest = false;
  double _lat = 0;
  double _long = 0;
  double _heading = 0;

  double get lat => _lat;
  double get long => _long;
  double get heading => _heading;

  // Static cache for last retrieved location (in-memory only)
  static GeoPoint? _lastLocation;
  static GeoPoint? get lastLocation => _lastLocation;
  static DateTime? _lastLocationAt;
  static const Duration _cacheMaxAge = Duration(seconds: 30);

  GeoPoint(double lat, double long, double heading) {
    _lat = lat;
    _long = long;
    _heading = heading;
  }

  /**
   * Get current location with optimized retrieval strategy
   *
   * This method first tries to get the last known position first (fast),
   * and if available, returns it immediately while requesting a fresh
   * location in the background. If no last known position is available,
   * it falls back to waiting for a fresh location.
   */
  static Future<GeoPoint> current() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Failed to enable location!!!!!!!!");
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print("permissions denied");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("permissions denied again");
          return Future.error('Location services are disabled.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        print("permissions denied");
        return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      // FASTEST PATH: Check our in-memory cache first (instant), but only if fresh
      if (_lastLocation != null && _lastLocationAt != null) {
        final cacheAge = DateTime.now().difference(_lastLocationAt!);
        if (cacheAge <= _cacheMaxAge) {
          print(
              "Using in-memory cached location (age ${cacheAge.inSeconds}s): ${_lastLocation!.lat}, ${_lastLocation!.long}");
          return _lastLocation!;
        }
      }

      // FAST PATH: Try to get last known position first (milliseconds)
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print(
            "Using last known position: ${lastPosition.latitude}, ${lastPosition.longitude}",
          );

          // Store in static cache
          _lastLocation = GeoPoint(
            lastPosition.latitude,
            lastPosition.longitude,
            lastPosition.heading,
          );
          _lastLocationAt = DateTime.now();

          // Start getting current position in background for better accuracy
          Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).then((pos) {
            print("Got updated location: ${pos.latitude}, ${pos.longitude}");
            _lastLocation = GeoPoint(pos.latitude, pos.longitude, pos.heading);
            _lastLocationAt = DateTime.now();
          }).catchError((e) {
            print("Error getting current position: $e");
          });

          // Return the last known position immediately
          return _lastLocation!;
        }
      } catch (e) {
        print("Error getting last known position: $e");
      }

      // SLOW PATH: If no last known position, wait for current position
      print("Getting location");
      final pos = await Geolocator.getCurrentPosition(
        // Ideally we would use best accuracy, but it doesn't work for some reason
        // desiredAccuracy: LocationAccuracy.best
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 3), // Give GPS time to get a fix
      );
      print("Got location: ${pos.latitude}, ${pos.longitude}");

      // Store in static cache
      _lastLocation = GeoPoint(pos.latitude, pos.longitude, pos.heading);
      _lastLocationAt = DateTime.now();
      return _lastLocation!;
    } catch (e) {
      print(e);
      return Future.error("Error:" + e.toString());
    }
  }

  double distanceTo(GeoPoint other) {
    return Geolocator.distanceBetween(_lat, _long, other._lat, other._long);
  }

  double bearingTo(GeoPoint other) {
    return Geolocator.bearingBetween(_lat, _long, other._lat, other._long);
  }

  static LocationSettings getLocationSettings() {
    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        //(Optional) Set foreground notification config to keep the app alive
        //when going to the background
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "CornellGO will continue to receive your location even when you aren't using it",
          notificationTitle: "Running in Background",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: false,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    return locationSettings;
  }
}
