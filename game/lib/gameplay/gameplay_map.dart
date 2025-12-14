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

class _GameplayMapState extends State<GameplayMap>
    with TickerProviderStateMixin {
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
  bool isHintDialogOpen = false;
  bool isHintAnimationInProgress = false;
  bool isHintButtonIlluminated = false;

  // Animation controllers for hint flow
  late AnimationController _circleShrinkController;
  late Animation<double> _circleShrinkAnimation;
  double? _oldHintRadius;
  double? _newHintRadius;

  // Animation controllers for zoom animations
  late AnimationController _zoomStage1Controller;
  late AnimationController _zoomStage2Controller;
  late Animation<double> _zoomStage1Animation;
  late Animation<double> _zoomStage2Animation;

  // Store animation listeners for cleanup
  VoidCallback? _stage1Listener;
  VoidCallback? _stage2Listener;

  // Animation controllers for bear hint animation
  late AnimationController _bearSlideInController;
  late AnimationController _bearRotateController;
  late AnimationController _speechBubbleFadeController;
  late AnimationController _bearFadeController;
  late AnimationController _bearSlideOutController;
  late Animation<double> _bearSlideInAnimation;
  late Animation<double> _bearRotateAnimation;
  late Animation<double> _speechBubbleFadeAnimation;
  late Animation<double> _bearFadeAnimation;
  late Animation<double> _bearSlideOutAnimation;

  // Bear animation overlay
  OverlayEntry? _hintBearOverlayEntry;

  // Track current camera position for smooth animations
  LatLng? _currentCameraPosition;
  double? _currentZoom;

  // whether the picture is expanded over the map
  bool isExpanded = false;
  double pictureWidth = 80, pictureHeight = 80;
  Alignment pictureAlign = Alignment.topRight;

  // size variables for expanding picture for animation

  var pictureIcon = SvgPicture.asset("assets/icons/mapexpand.svg");
  // Onboarding: overlay entry for bear mascot messages during onboarding steps 7-10
  OverlayEntry? _bearOverlayEntry;

  // Switch between the two sizes
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

  void _removeBearOverlay() {
    _bearOverlayEntry?.remove();
    _bearOverlayEntry = null;
  }

  void _removeHintBearOverlay() {
    _hintBearOverlayEntry?.remove();
    _hintBearOverlayEntry = null;
  }

  /**
   * Shows the bear hint animation overlay
   */
  void _showHintBearAnimation() {
    _removeHintBearOverlay();

    // Reset all bear animation controllers to ensure clean start
    try {
      _bearSlideInController.reset();
      _bearRotateController.reset();
      _speechBubbleFadeController.reset();
      _bearFadeController.reset();
      _bearSlideOutController.reset();
    } catch (e) {
      // Controllers not initialized yet (e.g., during hot reload)
      // They will be reset when the animation actually starts
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    _hintBearOverlayEntry = OverlayEntry(
      builder: (context) => _HintBearAnimationWidget(
        bearSlideInAnimation: _bearSlideInAnimation,
        bearRotateAnimation: _bearRotateAnimation,
        speechBubbleFadeAnimation: _speechBubbleFadeAnimation,
        bearFadeAnimation: _bearFadeAnimation,
        bearSlideOutAnimation: _bearSlideOutAnimation,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ),
    );
    Overlay.of(context).insert(_hintBearOverlayEntry!);
  }

  void _showImageToggleBearOverlay() {
    _removeBearOverlay();
    _bearOverlayEntry = OverlayEntry(
      builder: (context) => BearMascotMessage(
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
          _removeBearOverlay();
          ShowcaseView.getNamed("gameplay_map").dismiss();
          Provider.of<OnboardingModel>(context, listen: false).completeStep7();
          _toggle();
        },
      ),
    );
    Overlay.of(context).insert(_bearOverlayEntry!);
  }

  void _showRecenterBearOverlay() {
    _removeBearOverlay();
    _bearOverlayEntry = OverlayEntry(
      builder: (context) => BearMascotMessage(
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
          _removeBearOverlay();
          ShowcaseView.getNamed("gameplay_map").dismiss();
          Provider.of<OnboardingModel>(context, listen: false).completeStep9();
        },
      ),
    );
    Overlay.of(context).insert(_bearOverlayEntry!);
  }

  void _showHintBearOverlay() {
    _removeBearOverlay();
    _bearOverlayEntry = OverlayEntry(
      builder: (context) => BearMascotMessage(
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
          _removeBearOverlay();
          ShowcaseView.getNamed("gameplay_map").dismiss();
          Provider.of<OnboardingModel>(context, listen: false).completeStep10();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNavBar()),
          );
        },
      ),
    );
    Overlay.of(context).insert(_bearOverlayEntry!);
  }

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcon();
    streamStarted = startPositionStream();
    setStartingHintCircle();

    // Initialize animation controllers
    _circleShrinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _zoomStage1Controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _zoomStage2Controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize bear hint animation controllers
    _bearSlideInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bearRotateController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _speechBubbleFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bearFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bearSlideOutController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create animation for circle shrinking
    _circleShrinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _circleShrinkController,
        curve: Curves.easeInOut,
      ),
    );

    // Create zoom animations
    _zoomStage1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _zoomStage1Controller,
        curve: Curves.elasticOut,
      ),
    );

    _zoomStage2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _zoomStage2Controller,
        curve: Curves.elasticOut,
      ),
    );

    // Create bear hint animations
    _bearSlideInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bearSlideInController,
        curve: Curves.easeOut,
      ),
    );

    _bearRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bearRotateController,
        curve: Curves.easeOut,
      ),
    );

    _speechBubbleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _speechBubbleFadeController,
        curve: Curves.easeIn,
      ),
    );

    _bearFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bearFadeController,
        curve: Curves.easeInOut,
      ),
    );

    _bearSlideOutAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bearSlideOutController,
        curve: Curves.easeIn,
      ),
    );

    // Add listener to update UI during circle animation
    _circleShrinkController.addListener(() {
      if (isHintAnimationInProgress) {
        setState(() {});
      }
    });

    // Onboarding: Register showcase scope for highlighting UI elements (steps 7-10)
    // Hot restart fix: Unregister old instance if it exists, then register new one
    try {
      ShowcaseView.getNamed("gameplay_map").unregister();
    } catch (e) {
      // Not registered yet, that's fine
    }
    ShowcaseView.register(
      scope: "gameplay_map",
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
    _removeBearOverlay();
    _removeHintBearOverlay();
    positionStream.cancel();
    _disposeController();
    _circleShrinkController.dispose();
    _zoomStage1Controller.dispose();
    _zoomStage2Controller.dispose();
    _bearSlideInController.dispose();
    _bearRotateController.dispose();
    _speechBubbleFadeController.dispose();
    _bearFadeController.dispose();
    _bearSlideOutController.dispose();
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
   * Calculates the appropriate zoom level to ensure a circle of given radius
   * (in meters) is fully visible on screen with some padding.
   * 
   * @param radiusMeters - The radius of the circle in meters
   * @param centerLat - The latitude of the circle center (affects meters per pixel)
   * @param screenWidthPixels - The actual screen width in pixels
   * @param paddingFactor - Factor to add padding (default 2.5 means 150% extra space)
   * @returns The maximum zoom level that keeps the circle in frame
   */
  double _calculateZoomForRadius(
      double radiusMeters, double centerLat, double screenWidthPixels,
      {double paddingFactor = 2.5}) {
    // Diameter of circle in meters (with generous padding to ensure it fits)
    // Use diameter * paddingFactor to ensure the entire circle fits with margin
    final double diameterWithPadding = radiusMeters * 2 * paddingFactor;

    // Calculate how many meters per pixel we need to show the circle
    final double metersPerPixel = diameterWithPadding / screenWidthPixels;

    // Google Maps zoom formula: metersPerPixel = 156543.03392 * cos(lat) / 2^zoom
    // Solving for zoom: zoom = log2(156543.03392 * cos(lat) / metersPerPixel)
    final double metersPerPixelAtEquator = 156543.03392;
    final double cosLat = cos(centerLat * pi / 180.0);
    final double zoom =
        log(metersPerPixelAtEquator * cosLat / metersPerPixel) / ln2;

    // Clamp zoom to reasonable bounds (typically 10-20 for street level)
    return zoom.clamp(10.0, 20.0);
  }

  /**
   * Calculates the new hint values (radius and center) without applying them.
   * Returns a map with 'radius' and 'center' keys, or null if calculation fails.
   */
  Map<String, dynamic>? _calculateNewHintValues() {
    if (numHintsLeft > 0 && hintCenter != null && startingHintCenter != null) {
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

      return {
        'radius': newRadius,
        'center': GeoPoint(newLat, newLong, 0),
      };
    }
    return null;
  }

  /** 
   * Handles logic to use a hint. This includes updating hints left, 
   * calculating the updated radius of the hint circle, and changing the
   * location of the hint center such that it still contains the awarding
   * radius.
   */
  void useHint() {
    var newValues = _calculateNewHintValues();
    if (newValues == null) {
      return;
    }

    // update event tracker with new hints left value
    var eventId = Provider.of<GroupModel>(context, listen: false).curEventId;
    if (eventId == null) {
      displayToast("Could not get event", Status.error);
      return;
    } else {
      Provider.of<TrackerModel>(context, listen: false)
          .useEventTrackerHint(eventId);
    }

    hintRadius = newValues['radius'] as double;
    hintCenter = newValues['center'] as GeoPoint;
    // updates the widget's state, causing it to rebuild
    setState(() {});
  }

  void _openHintDialog() {
    setState(() {
      isHintDialogOpen = true;
      isHintButtonIlluminated = true;
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Container(
          child: Dialog(
            elevation: 16,
            insetPadding: EdgeInsets.zero,
            child: SizedBox(
              width: 334,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: displayHintDialog(dialogContext),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted && !isHintAnimationInProgress) {
        setState(() {
          isHintDialogOpen = false;
          isHintButtonIlluminated = false;
        });
      }
    });
  }

  void _startHintAnimationFlow() {
    if (!(numHintsLeft > 0 &&
        hintCenter != null &&
        startingHintCenter != null)) {
      setState(() {
        isHintDialogOpen = false;
        isHintAnimationInProgress = false;
        isHintButtonIlluminated = false;
      });
      return;
    }

    final previousHints = numHintsLeft;

    setState(() {
      isHintDialogOpen = false;
      isHintAnimationInProgress = true;
    });

    useHint();

    setState(() {
      numHintsLeft = max(previousHints - 1, 0);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        isHintAnimationInProgress = false;
        isHintButtonIlluminated = false;
      });
    });
  }

  /**
   * Animation flow for using a hint
   */
  Future<void> _startHintAnimationFlowWithAnimations() async {
    if (!(numHintsLeft > 0 &&
        hintCenter != null &&
        startingHintCenter != null)) {
      setState(() {
        isHintDialogOpen = false;
        isHintAnimationInProgress = false;
        isHintButtonIlluminated = false;
      });
      return;
    }

    final previousHints = numHintsLeft;

    // Store old radius before updating
    _oldHintRadius = hintRadius ?? defaultHintRadius;

    setState(() {
      isHintDialogOpen = false;
      isHintAnimationInProgress = true;
      isHintButtonIlluminated = true;
    });

    // Calculate new hint values using existing logic
    var newValues = _calculateNewHintValues();
    if (newValues == null) {
      setState(() {
        isHintAnimationInProgress = false;
        isHintButtonIlluminated = false;
      });
      return;
    }

    // Update event tracker
    var eventId = Provider.of<GroupModel>(context, listen: false).curEventId;
    if (eventId == null) {
      displayToast("Could not get event", Status.error);
      setState(() {
        isHintAnimationInProgress = false;
        isHintButtonIlluminated = false;
      });
      return;
    }

    Provider.of<TrackerModel>(context, listen: false)
        .useEventTrackerHint(eventId);

    _newHintRadius = newValues['radius'] as double;
    hintCenter = newValues['center'] as GeoPoint;

    setState(() {
      numHintsLeft = max(previousHints - 1, 0);
    });

    GoogleMapController googleMapController = await mapCompleter.future;

    // Helper function to calculate intermediate position
    LatLng _offsetTowards(LatLng from, LatLng to, double t) {
      return LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
    }

    // Step 1: Zoom into the blue circle with two-part animation using AnimationControllers
    if (hintCenter != null) {
      final finalTarget = LatLng(hintCenter!.lat, hintCenter!.long);
      await Future.delayed(const Duration(milliseconds: 1000));

      // Use current camera position if available, otherwise use current location
      final startPosition = _currentCameraPosition ??
          (currentLocation != null
              ? LatLng(currentLocation!.lat, currentLocation!.long)
              : _center);

      // Calculate intermediate target
      final intermediateTarget =
          _offsetTowards(startPosition, finalTarget, 0.7);

      // Get current zoom or use default
      final startZoom = _currentZoom ?? 16.0;

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final screenSizePixels = min(screenWidth, screenHeight);

      final circleRadius = _newHintRadius ?? hintRadius ?? defaultHintRadius;
      final double paddingFactor = circleRadius < 60 ? 4.0 : 2.5;
      final calculatedZoom = _calculateZoomForRadius(
          circleRadius, finalTarget.latitude, screenSizePixels,
          paddingFactor: paddingFactor);

      // Ensure the circle always fits on screen
      final targetZoom = min(calculatedZoom, 18.0).clamp(startZoom, 18.0);

      final intermediateZoom = startZoom + (targetZoom - startZoom) * 0.6;

      try {
        if (_zoomStage1Controller.isAnimating) {
          _zoomStage1Controller.stop();
        }
        _zoomStage1Controller.reset();
      } catch (e) {
        // Fallback: if controllers aren't initialized, use simple animation
        await googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: intermediateTarget,
              zoom: intermediateZoom,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        await googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: finalTarget,
              zoom: 18.0,
            ),
          ),
        );
        return;
      }

      // Set up animation values for Stage 1
      final stage1StartZoom = startZoom;
      final stage1EndZoom = intermediateZoom;
      final stage1StartPos = startPosition;
      final stage1EndPos = intermediateTarget;

      _stage1Listener = () {
        final t = _zoomStage1Animation.value;
        final currentZoom =
            stage1StartZoom + (stage1EndZoom - stage1StartZoom) * t;
        final currentPos = _offsetTowards(stage1StartPos, stage1EndPos, t);

        googleMapController.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentPos,
              zoom: currentZoom,
            ),
          ),
        );
      };

      _zoomStage1Controller.addListener(_stage1Listener!);
      await _zoomStage1Controller.forward();
      if (_stage1Listener != null) {
        _zoomStage1Controller.removeListener(_stage1Listener!);
        _stage1Listener = null;
      }

      await Future.delayed(const Duration(milliseconds: 300));

      // Stage 2: Animate to final position with elastic bo
      try {
        if (_zoomStage2Controller.isAnimating) {
          _zoomStage2Controller.stop();
        }
        _zoomStage2Controller.reset();
      } catch (e) {
        return;
      }

      // Set up animation values for Stage 2
      final stage2StartZoom = intermediateZoom;
      final stage2EndZoom = targetZoom;
      final stage2StartPos = intermediateTarget;
      final stage2EndPos = finalTarget;

      _stage2Listener = () {
        final t = _zoomStage2Animation.value;
        final currentZoom =
            stage2StartZoom + (stage2EndZoom - stage2StartZoom) * t;
        final currentPos = _offsetTowards(stage2StartPos, stage2EndPos, t);

        googleMapController.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentPos,
              zoom: currentZoom,
            ),
          ),
        );
      };

      _zoomStage2Controller.addListener(_stage2Listener!);
      await _zoomStage2Controller.forward();
      if (_stage2Listener != null) {
        _zoomStage2Controller.removeListener(_stage2Listener!);
        _stage2Listener = null;
      }
    }

    _showHintBearAnimation();

    // Phase 1: Slide in halfway with 15 degree tilt
    _bearSlideInController.reset();
    await _bearSlideInController.animateTo(0.5);

    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 2: Rotate back to normal while sliding in fully
    _bearRotateController.reset();
    await Future.wait([
      _bearSlideInController.forward(), // Continue from 0.5 to 1.0
      _bearRotateController.forward(), // Rotate from 15 to 0 degrees
    ]);

    // Phase 3: Speech bubble fades in
    _speechBubbleFadeController.reset();
    await _speechBubbleFadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    // Animate circle shrinking
    _circleShrinkController.reset();
    hintRadius = _oldHintRadius;
    setState(() {});

    await _circleShrinkController.forward();

    // Update to final radius after animation
    hintRadius = _newHintRadius;
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 1000));
    // Phase 4: Fade to hint_animation3.svg with "Goodluck!" message
    _bearFadeController.reset();
    await _bearFadeController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 5: Slide bear out left and fade out speech bubble
    try {
      _bearSlideOutController.reset();
      await Future.wait([
        _bearSlideOutController.forward(),
        _speechBubbleFadeController.reverse(),
      ]);
    } catch (e) {}

    _removeHintBearOverlay();

    // Step 3: Recenter camera
    recenterCamera();

    // Step 4: Remove grey overlay after a short delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      return;
    }

    setState(() {
      isHintAnimationInProgress = false;
      isHintButtonIlluminated = false;
    });
  }

  // Build image toggle widget with optional onboarding showcase
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
      photoWidget = Showcase(
        key: onboarding.step8ExpandedImageKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
        targetPadding: EdgeInsets.zero,
        disposeOnTap: true,
        onTargetClick: () {
          onboarding.completeStep8();
          _toggle(); // minimize the image
          // (optional) immediately kick off Step 9
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step9RecenterButtonKey]);
              _showRecenterBearOverlay();
            }
          });
        },
        onBarrierClick: () {
          onboarding.completeStep8();
          _toggle();
        },
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
      imageToggle = Showcase(
        key: onboarding.step7ImageToggleKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025, // ~10px on 393px screen
          vertical: screenHeight * 0.012, // ~10px on 852px screen
        ),
        child: imageToggle,
      );
    }

    return imageToggle;
  }

  // Build recenter button with optional onboarding showcase
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
      svgIcon = Showcase(
        key: onboarding.step9RecenterButtonKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025, // ~10px on 393px screen
          vertical: screenHeight * 0.012, // ~10px on 852px screen
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

  // Build hint button with optional onboarding showcase
  Widget _buildHintButton(
    OnboardingModel onboarding,
    double screenWidth,
    double screenHeight,
  ) {
    final bool shouldHighlight = isHintDialogOpen ||
        isHintButtonIlluminated ||
        isHintAnimationInProgress;
    final Color iconColor = shouldHighlight
        ? const Color(0xFFFFAA5B)
        : (numHintsLeft == 0
            ? const Color.fromARGB(255, 217, 217, 217)
            : const Color.fromARGB(255, 131, 90, 124));
    final Color hintCountColor = shouldHighlight
        ? const Color(0xFFFFAA5B)
        : (numHintsLeft == 0
            ? const Color.fromARGB(255, 217, 217, 217)
            : const Color.fromARGB(255, 131, 90, 124));

    // 1. Build complete hint button with counter badge (without padding)
    Widget hintButton = Stack(
      children: [
        // hint button
        FloatingActionButton.extended(
          heroTag: "hint_button",
          onPressed: _openHintDialog,
          label: SvgPicture.asset("assets/icons/maphint.svg",
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: const CircleBorder(),
        ),
        // num hints left counter
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(5.0),
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
                color: hintCountColor,
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
      hintButton = Showcase(
        key: onboarding.step10HintButtonKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
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

        // Onboarding: Step 7 - Show showcase for image toggle button after info row explanation
        if (onboarding.step6InfoRowComplete &&
            !onboarding.step7ImageToggleComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step7ImageToggleKey]);
              // Show bear overlay on top of showcase
              _showImageToggleBearOverlay();
            }
          });
        }

        // Onboarding: Step 8 - Show showcase for expanded image view
        if (isExpanded &&
            onboarding.step7ImageToggleComplete &&
            !onboarding.step8ExpandedImageComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step8ExpandedImageKey]);
              // No bear overlay for step 8 - just transparent full-screen tap
            }
          });
        }

        // Onboarding: Step 9 - Show showcase for recenter button
        if (onboarding.step8ExpandedImageComplete &&
            !onboarding.step9RecenterButtonComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step9RecenterButtonKey]);
              // Show bear overlay on top of showcase
              _showRecenterBearOverlay();
            }
          });
        }

        // Onboarding: Step 10 - Final gameplay step showcases hint button, then navigates home
        if (onboarding.step9RecenterButtonComplete &&
            !onboarding.step10HintButtonComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ShowcaseView.getNamed("gameplay_map")
                  .startShowCase([onboarding.step10HintButtonKey]);
              // Show bear overlay on top of showcase
              _showHintBearOverlay();
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
                onCameraMove: (CameraPosition position) {
                  _currentCameraPosition = position.target;
                  _currentZoom = position.zoom;
                },
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
                      // Use animated radius if animation is in progress
                      double radiusValue;
                      if (isHintAnimationInProgress &&
                          _oldHintRadius != null &&
                          _newHintRadius != null &&
                          _circleShrinkAnimation.value < 1.0) {
                        // Interpolate between old and new radius during animation
                        radiusValue = _oldHintRadius! +
                            (_newHintRadius! - _oldHintRadius!) *
                                _circleShrinkAnimation.value;
                      } else {
                        radiusValue = hintRadius ?? defaultHintRadius;
                      }

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
            _buildImageToggle(
              onboarding,
              imageUrl,
              screenWidth,
              screenHeight,
            ),
            if (isHintAnimationInProgress)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: const Color.fromARGB(128, 217, 217, 217),
                  ),
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
                        onPressed: () {
                          Navigator.pop(context, false);
                          _startHintAnimationFlow();
                        },
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

  Widget displayHintDialog(BuildContext context) {
    return Container(
      height: 335,
      width: 334,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9.14),
        ),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 302,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 23,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            runAlignment: WrapAlignment.start,
                            spacing: 8,
                            runSpacing: 0,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isHintDialogOpen = false;
                                    isHintButtonIlluminated = false;
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(),
                                  child: SvgPicture.asset(
                                    'assets/icons/cancel.svg',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 21),
                        Container(
                          width: 302,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      numHintsLeft <= 0
                                          ? 'assets/icons/sweating_bear.svg'
                                          : 'assets/icons/hint_popup.svg',
                                      width: numHintsLeft <= 0 ? 134 : 186.72,
                                      height: numHintsLeft <= 0 ? 110 : null,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ]),
                        ),
                        const SizedBox(height: 21),
                        Container(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      numHintsLeft <= 0
                                          ? "You're out of Hints!"
                                          : 'Want to use a Hint?',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        height: 1.30,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    numHintsLeft <= 0
                                        ? Text(
                                            "Hints refresh on Monday or Buy One",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          )
                                        : Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'You have ',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: numHintsLeft.toString(),
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFFE95755),
                                                    fontSize: 14,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: numHintsLeft == 1
                                                      ? ' hint left for the week!'
                                                      : ' hints left for the week!',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 118,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isHintDialogOpen = false;
                                    isHintButtonIlluminated = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.all(10),
                                  minimumSize: const Size.fromHeight(40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      width: 1.5,
                                      color: numHintsLeft <= 0
                                          ? const Color(0xFFED5656)
                                          : const Color(0xFFEC5555),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Nevermind",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: numHintsLeft <= 0
                                        ? const Color(0xFFED5656)
                                        : const Color(0xFFEC5555),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            SizedBox(
                              width: 118,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (numHintsLeft > 0) {
                                    _startHintAnimationFlowWithAnimations();
                                  } else {
                                    // TODO: Implement buy hint functionality
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: numHintsLeft <= 0
                                      ? const Color(0xFFED5656)
                                      : const Color(0xFFEC5555),
                                  elevation: 0,
                                  padding: const EdgeInsets.all(10),
                                  minimumSize: const Size.fromHeight(40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: numHintsLeft <= 0
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Buy",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          SvgPicture.asset(
                                            'assets/icons/bearcoins.svg',
                                            width: 16,
                                            height: 16,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "20",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        "Use one Hint",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ]),
    );
  }
}

/**
 * Widget for the bear hint animation overlay
 */
class _HintBearAnimationWidget extends StatefulWidget {
  final Animation<double> bearSlideInAnimation;
  final Animation<double> bearRotateAnimation;
  final Animation<double> speechBubbleFadeAnimation;
  final Animation<double> bearFadeAnimation;
  final Animation<double> bearSlideOutAnimation;
  final double screenWidth;
  final double screenHeight;

  const _HintBearAnimationWidget({
    required this.bearSlideInAnimation,
    required this.bearRotateAnimation,
    required this.speechBubbleFadeAnimation,
    required this.bearFadeAnimation,
    required this.bearSlideOutAnimation,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<_HintBearAnimationWidget> createState() =>
      _HintBearAnimationWidgetState();
}

class _HintBearAnimationWidgetState extends State<_HintBearAnimationWidget> {
  String _currentMessage = "Here is your hint!";
  late VoidCallback _fadeListener;
  bool _messageChanged = false;

  @override
  void initState() {
    super.initState();
    // Listen to fade animation to switch message when it starts
    _fadeListener = () {
      if (widget.bearFadeAnimation.value > 0.0 && !_messageChanged) {
        if (mounted) {
          setState(() {
            _currentMessage = "Goodluck!";
            _messageChanged = true;
          });
        }
      }
    };
    widget.bearFadeAnimation.addListener(_fadeListener);

    widget.bearFadeAnimation.addStatusListener((status) {
      if (status == AnimationStatus.forward && !_messageChanged) {
        if (mounted) {
          setState(() {
            _currentMessage = "Goodluck!";
            _messageChanged = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    widget.bearFadeAnimation.removeListener(_fadeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = widget.screenWidth;
    final screenHeight = widget.screenHeight;

    // Bear sizing and positioning
    final bearWidth = screenWidth * 0.25;
    final bearHeight = screenHeight * 0.22;
    final bearLeft = 0.0;
    final bearBottom = screenHeight * 0.045;

    return IgnorePointer(
      child: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // Bear image
            AnimatedBuilder(
              animation: Listenable.merge([
                widget.bearSlideInAnimation,
                widget.bearRotateAnimation,
                widget.bearFadeAnimation,
                widget.bearSlideOutAnimation,
              ]),
              builder: (context, child) {
                final slideInProgress = widget.bearSlideInAnimation.value;
                final slideOutProgress = widget.bearSlideOutAnimation.value;
                final baseX =
                    bearLeft - (bearWidth * 1.6) * (1.0 - slideInProgress);
                final bearX = baseX - (bearWidth * slideOutProgress);

                final rotationDegrees =
                    (15.0 - widget.bearRotateAnimation.value * 15.0) *
                        (pi / 180.0);

                final bearOpacity2 = 1.0 - widget.bearFadeAnimation.value;
                final bearOpacity3 = widget.bearFadeAnimation.value;

                return Positioned(
                  left: bearX,
                  bottom: bearBottom,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: bearOpacity2,
                        child: Transform.rotate(
                          angle: widget.bearFadeAnimation.value > 0.0
                              ? 0.0
                              : rotationDegrees,
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/icons/hint_animation2.svg',
                            width: bearWidth,
                            height: bearHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: bearOpacity3,
                        child: Transform.translate(
                          offset: Offset(0, bearHeight * -0.08),
                          child: SvgPicture.asset(
                            'assets/icons/hint_animation3.svg',
                            width: bearWidth * 1.15,
                            height: bearHeight * 1.15,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Speech bubble
            AnimatedBuilder(
              animation: widget.speechBubbleFadeAnimation,
              builder: (context, child) {
                final messageBoxWidth = _currentMessage == "Goodluck!"
                    ? screenWidth * 0.3
                    : screenWidth * 0.4;
                final messageLeft = _currentMessage == "Goodluck!"
                    ? screenWidth * 0.28
                    : screenWidth * 0.38;
                final messageBottom = screenHeight * 0.265;
                final arrowWidth = screenWidth * 0.1;
                final arrowHeight = screenHeight * 0.04;

                return Positioned(
                  left: messageLeft - (messageBoxWidth / 2),
                  bottom: messageBottom,
                  child: Opacity(
                    opacity: widget.speechBubbleFadeAnimation.value,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Bubble
                          Container(
                            width: messageBoxWidth,
                            constraints: const BoxConstraints(maxWidth: 300),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              _currentMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                                height: 1.5,
                              ),
                            ),
                          ),

                          // Arrow
                          Positioned(
                            left: messageBoxWidth * 0.2,
                            bottom: -arrowHeight * 0.6,
                            child: SvgPicture.asset(
                              'assets/icons/bubblearrow.svg',
                              width: arrowWidth,
                              height: arrowHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
