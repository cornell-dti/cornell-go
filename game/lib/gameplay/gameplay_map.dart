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
import 'package:game/model/onboarding_model.dart';
import 'package:game/widgets/bear_mascot_message.dart';
import 'package:showcaseview/showcaseview.dart';

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
    super.initState();
    setCustomMarkerIcon();
    streamStarted = startPositionStream();
    setStartingHintCircle();

    // Hot restart fix: Unregister old instance if it exists, then register new one
    try {
      ShowcaseView.getNamed("gameplay_map").unregister();
    } catch (e) {
      // Not registered yet, that's fine
    }
    ShowcaseView.register(
      scope: "gameplay_map",
      onFinish: () {
        Provider.of<OnboardingModel>(context, listen: false).completeStep7();
      },
    );
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

  /// Build image toggle widget with optional onboarding showcase
  Widget _buildImageToggle(
    OnboardingModel onboarding,
    String imageUrl,
    double screenWidth,
    double screenHeight,
  ) {
    // 1. Build base photo widget
    Widget photoWidget = Align(
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
    );

    // 2. Step 8: Wrap photoWidget with showcase if expanded (do this before building imageToggle)
    if (isExpanded &&
        onboarding.step7ImageToggleComplete &&
        !onboarding.step8ExpandedImageComplete) {
      photoWidget = Showcase.withWidget(
        key: onboarding.step8ExpandedImageKey,
        disableMovingAnimation: true,
        targetPadding: EdgeInsets.all(0),
        container: GestureDetector(
          onTap: () {
            print("Tapped anywhere on step 8");
            ShowcaseView.getNamed("gameplay_map").dismiss();
            onboarding.completeStep8();
            _toggle();
          },
          child: Container(
            width: screenWidth,
            height: screenHeight,
            color: Colors.transparent,
          ),
        ),
        child: photoWidget,
      );
    }

    // 3. Build complete image toggle (photo + exit button)
    Widget imageToggle = Positioned(
      top: screenWidth * 0.05,
      right: screenWidth * 0.05,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: pictureWidth,
        height: pictureHeight,
        child: Stack(
          children: [
            photoWidget,
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
    );

    // 4. Step 7: Wrap imageToggle with showcase (small zoom button)
    if (onboarding.step6InfoRowComplete &&
        !onboarding.step7ImageToggleComplete) {
      imageToggle = Showcase.withWidget(
        key: onboarding.step7ImageToggleKey,
        disableMovingAnimation: true,
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025, // ~10px on 393px screen
          vertical: screenHeight * 0.012, // ~10px on 852px screen
        ),
        container: BearMascotMessage(
          message:
              'Click on the zoom button to get a better idea of what the location looks like!',
          showBear: true,
          bearAsset: 'standing',
          bearLeftPercent: -0.02,
          bearBottomPercent: 0.18,
          messageLeftPercent: 0.6,
          messageBottomPercent: 0.40,
          onTap: () {
            print("Tapped anywhere on step 7 - expanding image");
            ShowcaseView.getNamed("gameplay_map").dismiss();
            onboarding.completeStep7();
            // Expand the image to trigger step 8
            _toggle();
          },
        ),
        child: imageToggle,
      );
    }

    return imageToggle;
  }

  /// Build recenter button with optional onboarding showcase
  Widget _buildRecenterButton(
    OnboardingModel onboarding,
    double screenWidth,
    double screenHeight,
  ) {
    // 1. Build base SVG icon
    Widget svgIcon = SvgPicture.asset("assets/icons/maprecenter.svg",
        colorFilter: ColorFilter.mode(
            Color.fromARGB(255, 131, 90, 124), BlendMode.srcIn));

    // 2. Step 9: Wrap just the SVG with showcase
    if (onboarding.step8ExpandedImageComplete &&
        !onboarding.step9RecenterButtonComplete) {
      svgIcon = Showcase.withWidget(
        key: onboarding.step9RecenterButtonKey,
        disableMovingAnimation: true,
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025, // ~10px on 393px screen
          vertical: screenHeight * 0.012, // ~10px on 852px screen
        ),
        container: BearMascotMessage(
          message:
              'Use the Recenter to return the map view to your current location so you can stay oriented.',
          showBear: true,
          bearAsset: 'popup',
          bearLeftPercent: -0.095,
          bearBottomPercent: 0.2,
          messageLeftPercent: 0.55,
          messageBottomPercent: 0.42,
          onTap: () {
            print("Tapped anywhere on step 9");
            ShowcaseView.getNamed("gameplay_map").dismiss();
            onboarding.completeStep9();
          },
        ),
        child: svgIcon,
      );
    }

    // 3. Build button with the (potentially wrapped) SVG icon
    Widget button = FloatingActionButton.extended(
      heroTag: "recenter_button",
      onPressed: recenterCamera,
      label: svgIcon,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      shape: CircleBorder(),
    );

    // 4. Add padding outside everything
    return Padding(
      padding: EdgeInsets.only(bottom: 150.0),
      child: button,
    );
  }

  /// Build hint button with optional onboarding showcase
  Widget _buildHintButton(
    OnboardingModel onboarding,
    double screenWidth,
    double screenHeight,
  ) {
    // 1. Build complete hint button with counter badge (without padding)
    Widget hintButton = Stack(
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
    );

    // 2. Step 10: Wrap entire hint button (button + counter) with showcase
    if (onboarding.step9RecenterButtonComplete &&
        !onboarding.step10HintButtonComplete) {
      hintButton = Showcase.withWidget(
        key: onboarding.step10HintButtonKey,
        disableMovingAnimation: true,
        container: BearMascotMessage(
          message:
              'Stuck? Use a Hint to make the location circle smaller, helping you pinpoint the spot.',
          showBear: true,
          bearAsset: 'standing',
          bearLeftPercent: -0.02,
          bearBottomPercent: 0.18,
          messageLeftPercent: 0.6,
          messageBottomPercent: 0.40,
          onTap: () {
            print("Tapped anywhere on step 10");
            ShowcaseView.getNamed("gameplay_map").dismiss();
            onboarding.completeStep10();
            // Navigate back to home to show Profile tab highlight (step 11)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBar()),
            );
          },
        ),
        child: hintButton,
      );
    }

    // 3. Add padding outside showcase
    return Container(
      padding: EdgeInsets.only(bottom: 15.0),
      child: hintButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    // return FutureBuilder<bool>(
    //     future: streamStarted,
    //     builder: (context, AsyncSnapshot<bool> snapshot) {
    //       return !snapshot.hasData
    //           ? CircularIndicator()
    final client = Provider.of<ApiClient>(context);
    final onboarding = Provider.of<OnboardingModel>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

        // Start showcase when step 6 completes (small zoom button)
        if (onboarding.step6InfoRowComplete &&
            !onboarding.step7ImageToggleComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step7ImageToggleKey]);
            }
          });
        }

        // Start showcase when step 7 completes and image is expanded
        if (isExpanded &&
            onboarding.step7ImageToggleComplete &&
            !onboarding.step8ExpandedImageComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step8ExpandedImageKey]);
            }
          });
        }

        // Start showcase when step 8 completes (recenter button)
        if (onboarding.step8ExpandedImageComplete &&
            !onboarding.step9RecenterButtonComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step9RecenterButtonKey]);
            }
          });
        }

        // Start showcase when step 9 completes (hint button)
        if (onboarding.step9RecenterButtonComplete &&
            !onboarding.step10HintButtonComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step10HintButtonKey]);
            }
          });
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
                  _buildHintButton(
                    onboarding,
                    screenWidth,
                    screenHeight,
                  ),
                  _buildRecenterButton(
                    onboarding,
                    screenWidth,
                    screenHeight,
                  ),
                ],
              ),
            ),
            _buildImageToggle(
              onboarding,
              imageUrl,
              screenWidth,
              screenHeight,
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
