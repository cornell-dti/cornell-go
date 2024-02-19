import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/foundation/key.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';

class GameplayMap extends StatefulWidget {
  const GameplayMap({Key? key}) : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  // final mapController = MapController();
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-33.86, 151.20);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
            target: _center,
            zoom: 11.0,
          ),
          // markers: {
          //   const Marker(
          //     markerId: const MarkerId("Sydney"),
          //     position: LatLng(-33.86, 151.20),
          //     infoWindow: InfoWindow(
          //       title: "Sydney",
          //       snippet: "Capital of New South Wales",
          //     ),
          //   ),
          // },
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
