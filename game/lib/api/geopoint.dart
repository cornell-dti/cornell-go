import 'package:geolocator/geolocator.dart';

class GeoPoint {
  double _lat = 0;
  double _long = 0;

  double get lat => _lat;
  double get long => _long;

  GeoPoint(double lat, double long) {
    _lat = lat;
    _long = long;
  }

  static Future<GeoPoint> current() async {
    final pos = await Geolocator.getCurrentPosition();

    return GeoPoint(pos.latitude, pos.longitude);
  }

  double distanceTo(GeoPoint other) {
    return Geolocator.distanceBetween(_lat, _long, other._lat, other._long);
  }
}
