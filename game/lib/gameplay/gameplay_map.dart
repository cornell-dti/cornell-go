// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:location/location.dart';
import 'package:game/api/location_api.dart';
import 'dart:async';

class GameplayMap extends StatefulWidget {
  const GameplayMap({Key? key}) : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  AndroidMapRenderer mapRenderer = AndroidMapRenderer.platformDefault;

  // final mapController = MapController();
  late Completer<GoogleMapController> mapController = Completer();

  // final LatLng _center = const LatLng(-33.86, 151.20);

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController.complete(controller);
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      WidgetsFlutterBinding.ensureInitialized();
      mapRenderer = await mapsImplementation
          .initializeWithRenderer(AndroidMapRenderer.latest);
    }
  }

  LocationData? currentLocation;

  void getCurrentLocation() async {
    Location location = Location();

    GoogleMapController googleMapController = await mapController.future;
    MapLocation.getCurrentLocation().then(
      (location) {
        currentLocation = location;
      },
    );

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;

      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 13.5,
            target: LatLng(newLoc.latitude!, newLoc.longitude!),
          ),
        ),
      );
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
        body: currentLocation == null
            ? const Center(child: Text("Loading"))
            : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!),
                  zoom: 11.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    position: LatLng(currentLocation!.latitude!,
                        currentLocation!.longitude!),
                    infoWindow: InfoWindow(
                      title: "Your Location",
                      snippet: "",
                    ),
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
