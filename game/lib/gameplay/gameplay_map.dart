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
  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    setCustomMarkerIcon();
    startPositionStream();
    super.initState();
  }

  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final LatLng _center = const LatLng(42.447, -76.4875);

  // User's current location will fall back to _center when current location
  // cannot be found
  GeoPoint? currentLocation;

  // hard coded target for testing
  // TODO: connect target location and radius to backend
  GeoPoint targetLocation = GeoPoint(42.4475, -76.4879, 0);
  double arrivalRadius = 10.0;

  // whether the picture is expanded over the map
  bool isExpanded = false;

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapCompleter.complete(controller);
  }

  /**
   * Starts the user's current location streaming upon state initialization
   * Sets the camera to center on user's location by default
   */
  void startPositionStream() async {
    GoogleMapController googleMapController = await mapCompleter.future;

    GeoPoint.current().then(
      (location) {
        currentLocation = location;
      },
    );

    positionStream = Geolocator.getPositionStream(
            locationSettings: GeoPoint.getLocationSettings())
        .listen((Position? newPos) {
      // prints user coordinates - useful for debugging
      // print(newPos == null
      //     ? 'Unknown'
      //     : '${newPos.latitude.toString()}, ${newPos.longitude.toString()}');

      // putting the animate camera logic in here seems to not work
      // could be useful to debug later?
      currentLocation = newPos == null
          ? GeoPoint(_center.latitude, _center.longitude, 0)
          : GeoPoint(newPos.latitude, newPos.longitude, newPos.heading);
    });

    positionStream.onData((newPos) {
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

  /**
   * Recenters the camera onto the user's current location and will keep
   * camera centered until position stream's event handler is replaced
   */
  void recenterCamera() async {
    GoogleMapController googleMapController = await mapCompleter.future;

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation!.lat, currentLocation!.long),
          zoom: 16.5,
        ),
      ),
    );

    positionStream.onData((newPos) {
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

  /**
   * Replaces the position stream event handler to stop recentering the
   * camera on the user's location
   */
  void cancelRecenterCamera() async {
    positionStream.onData((newPos) {
      currentLocation =
          GeoPoint(newPos.latitude, newPos.longitude, newPos.heading);
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
          body: Listener(
            onPointerDown: (e) {
              cancelRecenterCamera();
            },
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
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
                  rotation:
                      currentLocation == null ? 0 : currentLocation!.heading,
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
          floatingActionButton: Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: FloatingActionButton.extended(
                      onPressed: recenterCamera,
                      label: Icon(Icons.lightbulb,
                          color: Color.fromARGB(255, 223, 84, 84)),
                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      shape: CircleBorder(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 150.0),
                    child: FloatingActionButton.extended(
                      onPressed: recenterCamera,
                      label: Icon(Icons.location_on,
                          color: Color.fromARGB(255, 223, 84, 84)),
                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      shape: CircleBorder(),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 24.0, top: 40.0),
                child: isExpanded
                    ? Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.9,
                        alignment: Alignment.topCenter,
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.asset('assets/images/main-bg.jpeg'),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: FloatingActionButton(
                                onPressed: () {
                                  setState(() {
                                    isExpanded = false;
                                  });
                                },
                                child: Icon(Icons.close,
                                    color: Color.fromARGB(255, 223, 84, 84)),
                                backgroundColor:
                                    Color.fromARGB(255, 255, 255, 255),
                                shape: CircleBorder(),
                              ),
                            )
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = true;
                          });
                        },
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/main-bg.jpeg',
                                fit: BoxFit.cover,
                                width: 100,
                                height: 120,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.circle,
                                  size: 50,
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          )),
    );
  }
}
