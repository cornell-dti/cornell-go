import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  static bool didMakeRequest = false;
  double _lat = 0;
  double _long = 0;

  double get lat => _lat;
  double get long => _long;

  static bool _isRequestingLocationPermissions = false;
  static bool _isRequestingLocation = false;

  GeoPoint(double lat, double long) {
    _lat = lat;
    _long = long;
  }

  static Future<GeoPoint?> current() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    if (_isRequestingLocationPermissions || _isRequestingLocation) {
      //To handle the case where a request is already occuring.

      return null;
    }

    try {
      _isRequestingLocationPermissions = true;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location services are disabled.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      final pos = await Geolocator.getCurrentPosition();
      return GeoPoint(pos.latitude, pos.longitude);
    } catch (e) {
      return Future.error(e.toString());
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
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          ));
    } else if (Platform.isIOS || Platform.isMacOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
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
