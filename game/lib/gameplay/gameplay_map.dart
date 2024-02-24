import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:game/api/geopoint.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GameplayMap extends StatefulWidget {
  const GameplayMap({Key? key}) : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  late Completer<GoogleMapController> mapCompleter = Completer();

  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final LatLng _center = const LatLng(40.00, -70.00);

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapCompleter.complete(controller);
  }

  GeoPoint? currentLocation;

  void getCurrentLocation() async {
    GoogleMapController googleMapController = await mapCompleter.future;
    GeoPoint.current().then(
      (location) {
        currentLocation = location;
      },
    );

    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
            locationSettings: GeoPoint.getLocationSettings())
        .listen((Position? newPos) {
      // prints user coordinates - useful for debugging
      // print(newPos == null
      //     ? 'Unknown'
      //     : '${newPos.latitude.toString()}, ${newPos.longitude.toString()}');

      currentLocation =
          newPos == null ? null : GeoPoint(newPos.latitude, newPos.longitude);
    });

    positionStream.onData((newPos) {
      print('${newPos.latitude.toString()}, ${newPos.longitude.toString()}');
      currentLocation = GeoPoint(newPos.latitude, newPos.longitude);

      // upon new user location data, moves map camera to be centered around
      // new position and sets zoom.
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 16.5,
            target: LatLng(newPos.latitude, newPos.longitude),
          ),
        ),
      );
      setState(() {});
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          elevation: 2,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: currentLocation == null
                ? _center
                : LatLng(currentLocation!.lat, currentLocation!.lat),
            zoom: 11.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("currentLocation"),
              position: currentLocation == null
                  ? _center
                  : LatLng(currentLocation!.lat, currentLocation!.long),
            ),
          },
        ),
      ),
    );
  }
}
