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
          return Future.error('Location permissions are denied');
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
}
