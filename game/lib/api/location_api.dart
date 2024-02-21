import 'package:location/location.dart';

class MapLocation {
  MapLocation() {}

  static Future<LocationData> getCurrentLocation() async {
    Location location = new Location();
    location.enableBackgroundMode(enable: true);

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return Future.error('Location services are disabled.');
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return Future.error('Location permissions are denied.');
      }
    }

    _locationData = await location.getLocation();
    return _locationData;
  }
}
