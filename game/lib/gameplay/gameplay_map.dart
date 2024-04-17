import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:game/api/geopoint.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math';

class GameplayMap extends StatefulWidget {
  final GeoPoint targetLocation;
  final double awardingRadius;
  final String description;
  final int points;

  const GameplayMap(
      {Key? key,
      required this.targetLocation,
      required this.awardingRadius,
      required this.description,
      required this.points})
      : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  final METERS_TO_DEGREES = 111139;

  late Completer<GoogleMapController> mapCompleter = Completer();
  late StreamSubscription<Position> positionStream;

  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final LatLng _center = const LatLng(42.447, -76.4875);

  // User's current location will fall back to _center when current location
  // cannot be found
  GeoPoint? currentLocation;

  int numHintsLeft = 3;
  GeoPoint? startingHintCenter;
  GeoPoint? hintCenter;
  double startingHintRadius = 100.0;
  double hintRadius = 100.0;

  // whether the picture is expanded over the map
  bool isExpanded = false;

  @override
  void initState() {
    setCustomMarkerIcon();
    startPositionStream();
    setStartingHintCenter();
    super.initState();
  }

  /**
   * Sets a center for the hint circle by random such that
   * the entire circle encompasses the awarding area denoted by
   * widget.targetLocation and widget.awardingRadius
   */
  void setStartingHintCenter() {
    Random _random = Random();

    // Calculate the max distance between the centers of the circles in meters
    double maxDistance = startingHintRadius - widget.awardingRadius;
    // Center for hint circle can be up to maxDistance away from targetLocation
    // Generate random angle
    double angle = _random.nextDouble() * 2 * pi;
    // Generate random distance within the maxDistance radius in meters
    double randomDistance = sqrt(_random.nextDouble()) * maxDistance;
    // Convert to distance in degrees of latitude and longitude
    randomDistance /= METERS_TO_DEGREES;
    // Calculate coordinates of the random point within the circle
    double dx = widget.targetLocation.lat + randomDistance * cos(angle);
    double dy = widget.targetLocation.long + randomDistance * sin(angle);

    startingHintCenter = GeoPoint(dx, dy, 0);
    hintCenter = startingHintCenter;
    print("starting hint center: " +
        startingHintCenter!.lat.toString() +
        startingHintCenter!.long.toString());
  }

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

  void useHint() {
    if (numHintsLeft > 0 && hintCenter != null && startingHintCenter != null) {
      double newRadius =
          hintRadius - (startingHintRadius - widget.awardingRadius) * 0.33;
      double newLat = hintCenter!.lat -
          (startingHintCenter!.lat - widget.targetLocation.lat) * 0.33;
      double newLong = hintCenter!.long -
          (startingHintCenter!.long - widget.targetLocation.long) * 0.33;
      numHintsLeft -= 1;
      hintRadius = newRadius;
      hintCenter = GeoPoint(newLat, newLong, 0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Listener(
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
                      rotation: currentLocation == null
                          ? 0
                          : currentLocation!.heading,
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: CircleId("hintCircle"),
                      center: hintCenter != null
                          ? LatLng(hintCenter!.lat, hintCenter!.long)
                          : _center,
                      radius: hintRadius,
                      strokeColor: Color.fromARGB(80, 30, 41, 143),
                      strokeWidth: 2,
                      fillColor: Color.fromARGB(80, 83, 134, 237),
                    )
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 70),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 237, 86, 86),
                    padding: EdgeInsets.only(
                        right: 15, left: 15, top: 10, bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // button's shape
                    ),
                  ),
                  child: Text(
                    "I've Arrived!",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 21,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFFFFFF)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white
                              .withOpacity(0.3), // Adjust opacity as needed
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Dialog(
                            elevation: 16, //arbitrary large number
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  10), // Same as the Dialog's shape
                              child: displayDialogue(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 15.0, right: 10.0),
                    child: Stack(
                      children: [
                        FloatingActionButton.extended(
                          onPressed: useHint,
                          label: SvgPicture.asset("assets/icons/maphint.svg"),
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          shape: CircleBorder(),
                        ),
                        Positioned(
                          top: -5,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.3), // Shadow color
                                  blurRadius: 5, // Spread radius
                                  offset: Offset(2,
                                      2), // Shadow position, you can adjust this
                                ),
                              ],
                            ),
                            child: Text(
                              numHintsLeft.toString(),
                              style: TextStyle(
                                color: Color.fromARGB(255, 237, 86, 86),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 150.0),
                    child: FloatingActionButton.extended(
                      onPressed: recenterCamera,
                      label: SvgPicture.asset("assets/icons/maprecenter.svg"),
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
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.topCenter,
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.asset('assets/images/main-bg.jpeg'),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isExpanded = false;
                                });
                              },
                              icon: Image.asset("assets/icons/mapexit.png"),
                            ),
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
                                height: 100,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(4.0),
                              child: SvgPicture.asset(
                                  "assets/icons/mapexpand.svg"),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          )),
    );
  }

  bool checkArrived() {
    return currentLocation!.distanceTo(widget.targetLocation) <=
        widget.awardingRadius;
  }

  Container displayDialogue() {
    return checkArrived()
        ? Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(top: 5),
                    child: Text(
                      "Congratulations!",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    )),
                Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "You have arrived at ${widget.description}!",
                    )),
                Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          "Found Location",
                        ),
                        Spacer(),
                        Text("+ " + widget.points.toString() + " points"),
                      ],
                    )),
                if (numHintsLeft < 3)
                  Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            "Used 1st Hint",
                          ),
                          Spacer(),
                          Text("- 25 points"),
                        ],
                      )),
                if (numHintsLeft < 2)
                  Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            "Used 2nd Hint",
                          ),
                          Spacer(),
                          Text("- 25 points"),
                        ],
                      )),
                if (numHintsLeft < 1)
                  Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            "Used 3rd Hint",
                          ),
                          Spacer(),
                          Text("- 25 points"),
                        ],
                      )),
                Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                        "Total Points: " +
                            (widget.points - 25 * (3 - numHintsLeft))
                                .toString(),
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Row(children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("EXIT",
                          style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              color: Color.fromARGB(255, 131, 90, 124)))),
                  Spacer(),
                  ElevatedButton(
                      onPressed: () =>
                          {useHint(), Navigator.pop(context, false)},
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                7.3), // Adjust the radius as needed
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 237, 86, 86)),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset("assets/icons/mapcamera.svg"),
                          Text("Take Photo (+25pt)",
                              style: TextStyle(color: Colors.white)),
                        ],
                      )),
                ])
              ],
            ),
          )
        : Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(top: 5),
                    child: Text(
                      "Nearly There!",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    )),
                Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Use a hint if needed, you are close!",
                    )),
                Row(children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                7.3), // Adjust the radius as needed
                          ),
                        ),
                        side: MaterialStateProperty.all<BorderSide>(
                          BorderSide(
                            color: Color.fromARGB(
                                255, 237, 86, 86), // Specify the border color
                            width: 2.0, // Specify the border width
                          ),
                        ),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                      ),
                      child: Text("Continue",
                          style: TextStyle(
                              color: Color.fromARGB(255, 237, 86, 86)))),
                  Spacer(),
                  ElevatedButton(
                      onPressed: () =>
                          {useHint(), Navigator.pop(context, false)},
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                7.3), // Adjust the radius as needed
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 237, 86, 86)),
                      ),
                      child: Text("Use Hint (${numHintsLeft} Left)",
                          style: TextStyle(color: Colors.white))),
                ])
              ],
            ),
          );
  }
}
