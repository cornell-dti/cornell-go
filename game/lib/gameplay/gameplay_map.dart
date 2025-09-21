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
import 'package:flutter_compass/flutter_compass.dart';

// for backend connection
import 'package:provider/provider.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/game_api.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/challenge_model.dart';

/*

* GameplayMap Widget
*
* Displays an interactive map for gameplay, showing the user's location,
* hint circles, and challenge-related information.
*
* @remarks
* This widget is responsible for handling user location updates, displaying
* hints, and managing the challenge completion process. It uses Google Maps
* for rendering the map and integrates with various game-related models and
* APIs to provide a seamless gameplay experience.
*
* @param challengeId - The unique identifier for the current challenge.
* @param targetLocation - The GeoPoint representing the target location for the challenge.
* @param awardingRadius - The radius (in meters) within which the challenge is considered complete.
* @param points - The number of points awarded for completing this challenge.
* @param startingHintsUsed - The number of hints already used for this challenge.
*
* @returns A StatefulWidget that renders the gameplay map and associated UI elements

*/

class GameplayMap extends StatefulWidget {
  final String challengeId;
  final GeoPoint targetLocation;
  final double awardingRadius;
  final int points;
  final int startingHintsUsed;

  const GameplayMap(
      {Key? key,
      required this.challengeId,
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
  double? compassHeading = 0.0;
  // Timer? mockHeadingTimer; // mock compass data

  // Add this to your state variables (After isExapnded)
  bool isArrivedButtonEnabled = true;

  // whether the picture is expanded over the map
  bool isExpanded = false;
  double pictureWidth = 80, pictureHeight = 80;
  Alignment pictureAlign = Alignment.topRight;

  // size variables for expanding picture for animation

  var pictureIcon = SvgPicture.asset("assets/icons/mapexpand.svg");

  /// Switch between the two sizes
  void _toggle() => setState(() {
        isExpanded = !isExpanded;

        if (isExpanded) {
          pictureHeight = MediaQuery.of(context).size.height * 0.60;
          pictureWidth = MediaQuery.of(context).size.width * 0.90;
          pictureAlign = Alignment.topCenter;
        } else {
          pictureHeight = pictureWidth = 80;
          pictureAlign = Alignment.topRight;
        }
      });

  @override
  void initState() {
    setCustomMarkerIcon();
    super.initState();
    streamStarted = startPositionStream();
    setStartingHintCircle();
    compassHeading = 0.0;

    // Listen to compass events
    FlutterCompass.events!.listen((event) {
      setState(() {
        compassHeading = event.heading;
      });
    });

    // Mock compass data for testing
    // mockHeadingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    //   setState(() {
    //     // Increment by 10 degrees
    //     compassHeading = (compassHeading! + 10) % 360;
    //     print('Updated compassHeading: $compassHeading');
    //   });
    // });
  }

  @override
  void didUpdateWidget(GameplayMap oldWidget) {
    // If challenge changed, reset hint state
    if (oldWidget.challengeId != widget.challengeId) {
      startingHintCenter = null;
      hintCenter = null;
      hintRadius = null;
      setStartingHintCircle();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // mockHeadingTimer?.cancel(); // mock compass data
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
    double calculation = defaultHintRadius -
        (defaultHintRadius - widget.awardingRadius) *
            0.33 *
            widget.startingHintsUsed;

    hintRadius = calculation;
    if (hintRadius == null) {
      hintRadius = defaultHintRadius;
    }

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

    try {
      final location = await GeoPoint.current();
      currentLocation = location;

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
    } catch (e) {
      print('Failed to get location: $e');

      displayToast("Not able to receive location. Please check permissions.",
          Status.error);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            // if the page state is still active, navigate to bottom navbar
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => BottomNavBar()),
              (route) => false,
            );
          }
        });
      });

      return false;
    }
  }

  /**
   * Recenters the camera onto the user's current location and will keep
   * camera centered until position stream's event handler is replaced
   */
  void recenterCamera() async {
    GoogleMapController googleMapController = await mapCompleter.future;

    if (currentLocation == null) {
      return;
    }

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

      // Calculate total hints: backend hints + this new hint we're about to use
      int totalHintsUsed = widget.startingHintsUsed + 1;

      // Calculate radius from default, accounting for ALL hints used on this challenge
      double calculatedRadius = defaultHintRadius -
          (defaultHintRadius - widget.awardingRadius) * 0.33 * totalHintsUsed;

      // Ensure radius never goes below awarding radius (safety check)
      double newRadius = calculatedRadius < widget.awardingRadius
          ? widget.awardingRadius
          : calculatedRadius;

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

  @override
  Widget build(BuildContext context) {
    // return FutureBuilder<bool>(
    //     future: streamStarted,
    //     builder: (context, AsyncSnapshot<bool> snapshot) {
    //       return !snapshot.hasData
    //           ? CircularIndicator()
    final client = Provider.of<ApiClient>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
        } else if ((tracker.curChallengeId ?? '') == widget.challengeId) {
          numHintsLeft = totalHints - tracker.hintsUsed;
        }
        var challenge = challengeModel.getChallengeById(widget.challengeId);

        if (challenge == null) {
          displayToast("Error getting challenge", Status.error);
        }

        var imageUrl = challenge?.imageUrl;
        if (imageUrl == null || imageUrl.length == 0) {
          imageUrl =
              "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png";
        }

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            StreamBuilder(
                stream: client.clientApi.disconnectedStream,
                builder: ((context, snapshot) {
                  // Redirect to login if server api is null
                  if (client.serverApi == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Clear entire navigation stack and push to login screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => SplashPageWidget()),
                        (route) => false,
                      );
                      displayToast("Signed out", Status.success);
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
                      : LatLng(currentLocation!.lat, currentLocation!.long),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    icon: currentLocationIcon,
                    position: currentLocation == null
                        ? _center
                        : LatLng(currentLocation!.lat, currentLocation!.long),
                    anchor: Offset(0.5, 0.5),
                    rotation: compassHeading ?? 0,
                  ),
                },
                circles: {
                  Circle(
                    circleId: CircleId("hintCircle"),
                    center: hintCenter != null
                        ? LatLng(hintCenter!.lat, hintCenter!.long)
                        : _center,
                    radius: () {
                      double radiusValue = hintRadius ?? defaultHintRadius;

                      // Safety check to prevent crashes
                      if (radiusValue.isNaN ||
                          radiusValue.isInfinite ||
                          radiusValue <= 0) {
                        return widget.awardingRadius
                            .clamp(10.0, defaultHintRadius);
                      }
                      return radiusValue.clamp(
                          widget.awardingRadius, defaultHintRadius);
                    }(),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "I've Arrived!",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 21,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                onPressed: () async {
                  if (!isArrivedButtonEnabled) return;

                  setState(() {
                    isArrivedButtonEnabled = false;
                  });

                  bool hasArrived = checkArrived();
                  String? chalName;
                  if (hasArrived) {
                    if (tracker == null || challenge == null) {
                      displayToast("An error occurred while getting challenge",
                          Status.error);
                    } else {
                      chalName = await apiClient.serverApi
                          ?.completedChallenge(CompletedChallengeDto());
                    }
                  }
                  final chalId = widget.challengeId;
                  showDialog(
                    context: context,
                    barrierDismissible: !hasArrived,
                    builder: (context) {
                      return Container(
                        margin: EdgeInsetsDirectional.only(start: 10, end: 10),
                        child: Dialog(
                          elevation: 16,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: displayDialog(
                                context, hasArrived, chalId, chalName),
                          ),
                        ),
                      );
                    },
                  ).then((_) {
                    // Re-enable the button after the dialog is closed
                    setState(() {
                      isArrivedButtonEnabled = true;
                    });
                  });
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
                          heroTag: "hint_button",
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
                      heroTag: "recenter_button",
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
              top: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: pictureWidth,
                height: pictureHeight,
                child: Stack(
                  children: [
                    // photo
                    Align(
                      alignment: pictureAlign,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: pictureWidth,
                          height: pictureHeight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          print("ICON TAPPED!"); // Debug print
                          _toggle();
                        },
                        child: Container(
                          width: 60, // Larger invisible hit-area
                          height: 60,
                          alignment: Alignment.topRight,
                          // Make the debug rectangle much more visible
                          child: SvgPicture.asset(
                            isExpanded
                                ? 'assets/icons/mapexit.svg'
                                : 'assets/icons/mapexpand.svg',
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
    // });
  }

  /** Returns whether the user is at the challenge location */
  bool checkArrived() {
    if (currentLocation == null) {
      return false;
    }
    return currentLocation!.distanceTo(widget.targetLocation) <=
        widget.awardingRadius;
  }

  Container displayDialog(BuildContext context, hasArrived, String challengeId,
      String? challengeName) {
    final name = challengeName ?? "";
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
                      "You've arrived at ${name}!",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    )),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
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
                            builder: (context) => ChallengeCompletedPage(
                                  challengeId: challengeId,
                                )),
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
                        "You're close, but not there yet." +
                            (numHintsLeft > 0
                                ? " Use a hint if needed! Each hint reduces reward by ~15%. Using all 3 hints yields half the points."
                                : ""),
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400))),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(
                                horizontal:
                                    (MediaQuery.devicePixelRatioOf(context) < 3
                                        ? 10
                                        : 15))),
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
                              fontSize:
                                  MediaQuery.devicePixelRatioOf(context) < 3
                                      ? 12
                                      : 14,
                              color: Color.fromARGB(255, 237, 86, 86)))),
                  if (numHintsLeft > 0) Spacer(),
                  if (numHintsLeft > 0)
                    ElevatedButton(
                        onPressed: () =>
                            {useHint(), Navigator.pop(context, false)},
                        style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                                  EdgeInsets.only(left: 15, right: 15)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7.3),
                            ),
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Color.fromARGB(255, 237, 86, 86)),
                        ),
                        child: Text("Use Hint (${numHintsLeft} Left)",
                            style: TextStyle(
                                fontSize:
                                    MediaQuery.devicePixelRatioOf(context) < 3
                                        ? 12
                                        : 14,
                                color: Colors.white))),
                ])
              ],
            ),
          );
  }
}
