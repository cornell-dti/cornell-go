// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:game/api/geopoint.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GameplayMap extends StatefulWidget {
  const GameplayMap({Key? key}) : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  // AndroidMapRenderer mapRenderer = AndroidMapRenderer.platformDefault;

  // final mapController = MapController();
  late Completer<GoogleMapController> mapCompleter = Completer();

  final LatLng _center = const LatLng(-33.86, 151.20);
  // final LatLng _center = const LatLng(40.00, -70.00);

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapCompleter.complete(controller);
  }

  // LocationData? currentLocation;
  GeoPoint? currentLocation;

  void getCurrentLocation() async {
    // GeoPoint location = GeoPoint(_center.latitude, _center.longitude);
    // final GoogleMapsFlutterPlatform mapsImplementation =
    //     GoogleMapsFlutterPlatform.instance;
    // if (mapsImplementation is GoogleMapsFlutterAndroid) {
    //   WidgetsFlutterBinding.ensureInitialized();
    //   mapRenderer = await mapsImplementation
    //       .initializeWithRenderer(AndroidMapRenderer.latest);
    // }

    GoogleMapController googleMapController = await mapCompleter.future;
    GeoPoint.current().then(
      (location) {
        currentLocation = location;
      },
    );

    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
            locationSettings: GeoPoint.getLocationSettings())
        .listen((Position? newPos) {
      print(newPos == null
          ? 'Unknown'
          : '${newPos.latitude.toString()}, ${newPos.longitude.toString()}');
      currentLocation =
          newPos == null ? null : GeoPoint(newPos.latitude, newPos.longitude);

      // googleMapController.animateCamera(
      //   CameraUpdate.newCameraPosition(
      //     CameraPosition(
      //       zoom: 21,
      //       target: newPos == null
      //           ? _center
      //           : LatLng(newPos.latitude, newPos.longitude),
      //     ),
      //   ),
      // );
    });

    positionStream.onData((newPos) {
      print('${newPos.latitude.toString()}, ${newPos.longitude.toString()}');
      currentLocation = GeoPoint(newPos.latitude, newPos.longitude);

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
    // return FlutterMap(
    //   options: MapOptions(
    //     center: LatLng(51.509364, -0.128928),
    //     zoom: 9.2,
    //   ),
    //   children: [
    //     TileLayer(
    //       urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    //       userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    //     ),
    //   ],
    // );
  }
}
