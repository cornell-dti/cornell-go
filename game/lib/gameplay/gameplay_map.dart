import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:game/api/geopoint.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math';
import 'package:game/gameplay/challenge_completed.dart';
import 'package:game/utils/utility_functions.dart';
import 'dart:ui' as ui;

// for backend connection
import 'package:provider/provider.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/game_api.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/challenge_model.dart';

class GameplayMap extends StatefulWidget {
  final GeoPoint targetLocation;
  final double awardingRadius;
  final int points;
  final int startingHintsUsed;

  const GameplayMap(
      {Key? key,
      required this.targetLocation,
      required this.awardingRadius,
      required this.points,
      required this.startingHintsUsed})
      : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  final METERS_TO_DEGREES = 111139;

  late Completer<GoogleMapController> mapCompleter = Completer();
  late StreamSubscription<Position> positionStream;
  // Whether location streaming has begun
  late Future<bool> streamStarted;

  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final LatLng _center = const LatLng(42.447, -76.4875);

  // User's current location will fall back to _center when current location
  // cannot be found
  GeoPoint? currentLocation;

  int totalHints = 3;
  int numHintsLeft = 10;
  GeoPoint? startingHintCenter;
  GeoPoint? hintCenter;
  double defaultHintRadius = 200.0;
  double? hintRadius;

  // whether the picture is expanded over the map
  bool isExpanded = false;

  @override
  void initState() {
    setCustomMarkerIcon();
    super.initState();
    streamStarted = startPositionStream();
    setStartingHintCircle();
  }

  @override
  void dispose() {
    positionStream.cancel();
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final GoogleMapController controller = await mapCompleter.future;
    controller.dispose();
  }

  /**
   * Sets a center for the hint circle by random such that
   * the entire circle encompasses the awarding area denoted by
   * widget.targetLocation and widget.awardingRadius.
   * 
   * Sets the radius for the hint circle based on the number of
   * hints used for this challenge already.
   */
  void setStartingHintCircle() {
    print(widget.startingHintsUsed);
    hintRadius = defaultHintRadius -
        (defaultHintRadius - widget.awardingRadius) *
            0.33 *
            widget.startingHintsUsed;
    if (hintRadius == null) {
      hintRadius = defaultHintRadius;
    }
    print(hintRadius);

    Random _random = Random();

    // Calculate the max distance between the centers of the circles in meters
    double maxDistance = hintRadius! - widget.awardingRadius;
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
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapCompleter.complete(controller);
  }

  /**
   * Starts the user's current location streaming upon state initialization
   * Sets the camera to center on user's location by default
   * 
   * Returns true if stream is successfully set up
   */
  Future<bool> startPositionStream() async {
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
      setState(() {});
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
    return true;
  }

  /**
   * Recenters the camera onto the user's current location and will keep
   * camera centered until position stream's event handler is replaced
   */
  void recenterCamera() async {
    GoogleMapController googleMapController = await mapCompleter.future;

    // recenters camera to user location
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation!.lat, currentLocation!.long),
          zoom: 16.5,
        ),
      ),
    );

    // Upon receiving new user location data, moves map camera to be centered
    // around new position and sets zoom. This causes the map to follow the
    // user as they move.
    positionStream.onData((newPos) {
      currentLocation =
          GeoPoint(newPos.latitude, newPos.longitude, newPos.heading);

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

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width, targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  /** 
   * Sets the custom user location icon, which is called upon
   * initializing the state
   */
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  void setCustomMarkerIcon() async {
    Uint8List newMarker =
        await getBytesFromAsset('assets/icons/userlocation.png', 200);
    currentLocationIcon = BitmapDescriptor.fromBytes(newMarker);
    setState(() {});
  }

  /** 
   * Handles logic to use a hint. This includes updating hints left, 
   * calculating the updated radius of the hint circle, and changing the
   * location of the hint center such that it still contains the awarding
   * radius.
   */
  void useHint() {
    if (numHintsLeft > 0 && hintCenter != null && startingHintCenter != null) {
      // update event tracker with new hints left value
      var eventId = Provider.of<GroupModel>(context, listen: false).curEventId;
      if (eventId == null) {
        displayToast("Could not get event", Status.error);
      } else {
        Provider.of<TrackerModel>(context, listen: false)
            .useEventTrackerHint(eventId);
      }

      // decreases radius by 0.33 upon each hint press
      // after 3 hints, hint radius will equal that of the awarding radius
      double newRadius = (hintRadius ?? defaultHintRadius) -
          (defaultHintRadius - widget.awardingRadius) * 0.33;
      double newLat = hintCenter!.lat -
          (startingHintCenter!.lat - widget.targetLocation.lat) * 0.33;
      double newLong = hintCenter!.long -
          (startingHintCenter!.long - widget.targetLocation.long) * 0.33;
      hintRadius = newRadius;
      hintCenter = GeoPoint(newLat, newLong, 0);
      // updates the widget's state, causing it to rebuild
      setState(() {});
    }
  }

  String? challengeName;
  // Used when user presses I've Arrived when they are within the awarding
  // radius. Messages the backend to complete the current challenge and update
  // event trackers.
  void completeChallenge() {
    var eventId = Provider.of<GroupModel>(context, listen: false).curEventId;
    var event = Provider.of<EventModel>(context, listen: false)
        .getEventById(eventId ?? "");
    var tracker = Provider.of<TrackerModel>(context, listen: false)
        .trackerByEventId(eventId ?? "");

    if (tracker == null) {
      displayToast(
          "An error occurred while getting event tracker", Status.error);
    } else {
      var challenge = Provider.of<ChallengeModel>(context, listen: false)
          .getChallengeById(tracker.curChallengeId);
      if (challenge == null) {
        displayToast("An error occurred while getting challenge", Status.error);
      } else {
        Provider.of<ApiClient>(context, listen: false)
            .serverApi
            ?.completedChallenge(
                CompletedChallengeDto(challengeId: challenge.id));
        setState(() {
          challengeName = challenge.name;
        });
      }
    }
  }

  // size variables for expanding picture for animation
  var pictureWidth = 80.0;
  var pictureHeight = 80.0;
  var pictureIcon = SvgPicture.asset("assets/icons/mapexpand.svg");
  var pictureAlign = Alignment.topRight;

  @override
  Widget build(BuildContext context) {
    // return FutureBuilder<bool>(
    //     future: streamStarted,
    //     builder: (context, AsyncSnapshot<bool> snapshot) {
    //       return !snapshot.hasData
    //           ? CircularIndicator()
    final client = Provider.of<ApiClient>(context);

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Consumer5<EventModel, GroupModel, TrackerModel, ChallengeModel,
              ApiClient>(
          builder: (context, eventModel, groupModel, trackerModel,
              challengeModel, apiClient, child) {
        EventTrackerDto? tracker =
            trackerModel.trackerByEventId(groupModel.curEventId ?? "");
        if (tracker == null) {
          displayToast("Error getting event tracker", Status.error);
        } else {
          numHintsLeft = totalHints - tracker.hintsUsed;
        }
        var challenge =
            challengeModel.getChallengeById(tracker?.curChallengeId ?? '');

        return Scaffold(
            body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            StreamBuilder(
                stream: client.clientApi.disconnectedStream,
                builder: ((context, snapshot) {
                  if (client.serverApi == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SplashPageWidget()));
                      displayToast("Lost connection!", Status.success);
                    });
                  }

                  return Container();
                })),
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
                    anchor: Offset(0.5, 0.5),
                    rotation:
                        currentLocation == null ? 0 : currentLocation!.heading,
                  ),
                },
                circles: {
                  Circle(
                    circleId: CircleId("hintCircle"),
                    center: hintCenter != null
                        ? LatLng(hintCenter!.lat, hintCenter!.long)
                        : _center,
                    radius: (hintRadius ?? defaultHintRadius),
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
                  padding:
                      EdgeInsets.only(right: 15, left: 15, top: 10, bottom: 10),
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
                  bool hasArrived = checkArrived();
                  if (hasArrived) {
                    if (challenge == null) {
                      displayToast("An error occurred while getting challenge",
                          Status.error);
                    } else {
                      apiClient.serverApi?.completedChallenge(
                          CompletedChallengeDto(challengeId: challenge.id));
                      setState(() {
                        challengeName = challenge.name;
                      });
                    }
                  }
                  showDialog(
                    context: context,
                    barrierDismissible: !hasArrived,
                    builder: (context) {
                      return Container(
                        margin: EdgeInsetsDirectional.only(start: 10, end: 10),
                        child: Dialog(
                          elevation: 16, //arbitrary large number
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                10), // Same as the Dialog's shape
                            child: displayDialogue(hasArrived),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Positioned(
              bottom: 0,
              right: 10,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: Stack(
                      children: [
                        // hint button
                        FloatingActionButton.extended(
                          onPressed: useHint,
                          label: SvgPicture.asset("assets/icons/maphint.svg",
                              colorFilter: ColorFilter.mode(
                                  numHintsLeft == 0
                                      ? Color.fromARGB(255, 217, 217, 217)
                                      : Color.fromARGB(255, 131, 90, 124),
                                  BlendMode.srcIn)),
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          shape: CircleBorder(),
                        ),
                        // num hints left counter
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              numHintsLeft.toString(),
                              style: TextStyle(
                                color: numHintsLeft == 0
                                    ? Color.fromARGB(255, 217, 217, 217)
                                    : Color.fromARGB(255, 131, 90, 124),
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
                      label: SvgPicture.asset("assets/icons/maprecenter.svg",
                          colorFilter: ColorFilter.mode(
                              Color.fromARGB(255, 131, 90, 124),
                              BlendMode.srcIn)),
                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      shape: CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              // expandable image in top right of map
              // padding: EdgeInsets.only(left: 10.0, right: 10, top: 0.0),
              top: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
              child: GestureDetector(
                onTap: () {
                  isExpanded
                      ? setState(() {
                          isExpanded = false;
                          pictureHeight = 80.0;
                          pictureWidth = 80.0;
                          pictureIcon =
                              SvgPicture.asset("assets/icons/mapexpand.svg");
                          pictureAlign = Alignment.topRight;
                        })
                      : setState(() {
                          isExpanded = true;
                          pictureHeight =
                              MediaQuery.of(context).size.height * 0.6;
                          pictureWidth =
                              MediaQuery.of(context).size.width * 0.90;
                          pictureIcon =
                              SvgPicture.asset("assets/icons/mapexit.svg");
                          pictureAlign = Alignment.topCenter;
                        });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  width: pictureWidth,
                  height: pictureHeight,
                  child: Stack(
                    children: [
                      Container(
                        alignment: pictureAlign,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            challenge?.imageUrl ??
                                "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png",
                            fit: BoxFit.cover,
                            width: pictureWidth,
                            height: pictureHeight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Container(
                            alignment: Alignment.topRight, child: pictureIcon),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
      }),
    );
    // });
  }

  /** Returns whether the user is at the challenge location */
  bool checkArrived() {
    return currentLocation!.distanceTo(widget.targetLocation) <=
        widget.awardingRadius;
  }

  Container displayDialogue(bool hasArrived) {
    return hasArrived
        ? Container(
            // margin: EdgeInsetsDirectional.only(start: 50, end: 50),
            color: Colors.white,
            padding: EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(top: 5),
                    child: Text(
                      "Congratulations!",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )),
                Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "You've arrived at ${challengeName ?? ""}!",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    )),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: SvgPicture.asset('assets/images/arrived.svg',
                      fit: BoxFit.cover),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChallengeCompletedPage()),
                      );
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.only(left: 15, right: 15)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              7.3), // Adjust the radius as needed
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 237, 86, 86)),
                    ),
                    child: Text("Point Breakdown",
                        style: TextStyle(color: Colors.white)),
                  ),
                )
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
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    )),
                Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                        "You’re close, but not there yet. Use a hint if needed! Hints use 25 points.",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400))),
                Row(children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.only(left: 15, right: 15)),
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
                      child: Text("Nevermind",
                          style: TextStyle(
                              color: Color.fromARGB(255, 237, 86, 86)))),
                  Spacer(),
                  ElevatedButton(
                      onPressed: () =>
                          {useHint(), Navigator.pop(context, false)},
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.only(left: 20, right: 20)),
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
