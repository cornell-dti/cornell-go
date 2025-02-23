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

  GeoPoint(
    double lat,
    double long,
    double heading,
  ) {
    _lat = lat;
    _long = long;
    _heading = heading;
  }

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
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      print("Getting location");
      final pos = await Geolocator.getCurrentPosition(
          // Ideally we would use best accuracy, but it doesn't work for some reason
          // desiredAccuracy: LocationAccuracy.best
          desiredAccuracy: LocationAccuracy.medium);
      print("Got location: ${pos.latitude}, ${pos.longitude}");
      return GeoPoint(pos.latitude, pos.longitude, pos.heading);
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
