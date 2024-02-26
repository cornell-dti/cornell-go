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

  @override
  void initState() {
    getCurrentLocation();
    setCustomMarkerIcon();
    super.initState();
  }

  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final LatLng _center = const LatLng(40.00, -70.00);

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapCompleter.complete(controller);
  }

  GeoPoint? currentLocation;
  GeoPoint targetLocation = GeoPoint(42.4475, -76.4879, 0);
  double arrivalRadius = 10.0;

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

      // putting the animate camera logic in here seems to not work
      // could be useful to debug later?
      currentLocation = newPos == null
          ? null
          : GeoPoint(newPos.latitude, newPos.longitude, newPos.heading);
    });

    positionStream.onData((newPos) {
      print('${newPos.latitude.toString()}, ${newPos.longitude.toString()}');
      currentLocation =
          GeoPoint(newPos.latitude, newPos.longitude, newPos.heading);

      // upon new user location data, moves map camera to be centered around
      // new position and sets zoom.
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(newPos.latitude, newPos.longitude),
            zoom: 16.5,
          ),
        ),
      );
      setState(() {});
    });
  }

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, "assets/icons/userlocation.png")
        .then(
      (icon) {
        currentLocationIcon = icon;
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: currentLocation == null
                ? _center
                : LatLng(currentLocation!.lat, currentLocation!.lat),
            zoom: 11,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("currentLocation"),
              icon: currentLocationIcon,
              position: currentLocation == null
                  ? _center
                  : LatLng(currentLocation!.lat, currentLocation!.long),
              rotation: currentLocation == null ? 0 : currentLocation!.heading,
            ),
          },
          circles: {
            Circle(
              circleId: CircleId("hintCircle"),
              center: LatLng(targetLocation.lat, targetLocation.long),
              radius: 100,
              strokeColor: Color.fromARGB(80, 30, 41, 143),
              strokeWidth: 2,
              fillColor: Color.fromARGB(80, 83, 134, 237),
            )
          },
        ),
      ),
    );
  }
}
