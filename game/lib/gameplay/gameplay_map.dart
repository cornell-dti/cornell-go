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
import 'package:game/gameplay/challenge_failed.dart';
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
import 'package:game/model/onboarding_model.dart';
import 'package:game/model/timer_model.dart';
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

  /// Extension duration in seconds (5 minutes).
  /// IMPORTANT: Must stay in sync with EXTENSION_LENGTH_MS in server/src/timer/timer.service.ts (in milliseconds).
  static const int EXTENSION_TIME_SECONDS = 300;

  late Completer<GoogleMapController> mapCompleter = Completer();
  late StreamSubscription<Position> positionStream;
  StreamSubscription<CompassEvent>? _compassSubscription;
  // Whether location streaming has begun
  late Future<bool> streamStarted;

  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final LatLng _center = const LatLng(42.447, -76.4875);

  // User's current location will fall back to _center when current location
  // cannot be found
  GeoPoint? currentLocation;

  // Timer
  String timeLeft = "--:--"; // Time left that is displayed to the user
  double currentTime = 0.0;
  int totalTime = 0;
  bool hasTimer = false;
  Timer? _timerUpdateTimer; // Periodic timer to update display every second
  bool _periodicTimerStarted = false;
  int _waitCount = 0; // Counts how long we've been waiting for backend

  /// Maximum time (in seconds) to wait for backend to respond when starting a timer.
  /// After this timeout, the timer UI will show an error and reset.
  static const int _maxBackendWaitTimeSeconds = 10;

  // Stream subscriptions for timer events
  StreamSubscription<TimerCompletedDto>? _timerCompletedSubscription;
  StreamSubscription<TimerExtendedDto>? _timerExtendedSubscription;
  StreamSubscription<TimerWarningDto>? _timerWarningSubscription;
  StreamSubscription<TimerStartedDto>? _timerStartedSubscription;

  bool _showWarningColors = false; // Show warning colors when 5 seconds left
  bool _hasStartedFlashing = false; // Track if flashing animation has started

  int totalHints = 3;
  int numHintsLeft = 10;
  GeoPoint? startingHintCenter;
  GeoPoint? hintCenter;
  double defaultHintRadius = 200.0;
  double? hintRadius;
  double _compassHeading = 0.0;

  // Add this to your state variables (After isExapnded)
  bool isArrivedButtonEnabled = true;

  // whether the picture is expanded over the map
  bool isExpanded = false;
  double pictureWidth = 80, pictureHeight = 80;
  Alignment pictureAlign = Alignment.topRight;

  // size variables for expanding picture for animation

  var pictureIcon = SvgPicture.asset("assets/icons/mapexpand.svg");
  // Onboarding: overlay entry for bear mascot messages during onboarding steps 7-10
  OverlayEntry? _bearOverlayEntry;

  // Timer: overlay entry for Time's Up message when timer expires
  OverlayEntry? _timerModalOverlay;
  bool _timerModalShowing = false; // Flag to prevent multiple overlays

  // Flag to track when "Congratulations" dialog is showing after challenge completion
  bool _arrivedDialogShowing = false;
  OverlayEntry?
      _timerWarningOverlay; // Current warning overlay entry for Niki warning the user of how much time is left

  // Timer: animation for extension button countdown
  AnimationController? _extensionAnimationController;
  Animation<double>? _extensionAnimation;

  /// Time window (in seconds) for the user to decide whether to extend the timer
  /// after the "Time's Up" modal appears. The extension button shows a countdown
  /// animation during this period; after it expires, the button becomes disabled.
  static const int _extensionChoiceWindowSeconds = 10;

  void _removeTimerWarning() {
    _timerWarningOverlay?.remove();
    _timerWarningOverlay = null;
  }

  void _displayTimerWarning(String timeLeft) {
    _removeTimerWarning();

    _timerWarningOverlay = OverlayEntry(
      builder: (context) => BearMascotMessage(
        message: '$timeLeft left!',
        showBear: true,
        bearAsset: 'popup',
        bearLeftPercent: -0.095,
        bearBottomPercent: 0.2,
        messageLeftPercent: 0.55,
        messageBottomPercent: 0.42,
        messageBoxWidthPercent: 0.45,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFFED5656),
          height: 1.5,
          decoration: TextDecoration.none,
        ),
      ),
    );
    Overlay.of(context).insert(_timerWarningOverlay!);

    // Auto-dismiss after 1 second
    Timer(Duration(seconds: 1), () {
      if (mounted) {
        _removeTimerWarning();
        // Clear warning after 1 second in TimerModel
        final timerModel = Provider.of<TimerModel>(context, listen: false);
        timerModel.clearWarning();
      }
    });
  }

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

  /**
   * Starts periodic updates to refresh timer display every second)
   * Waits for backend to respond (isActive becomes true) before displaying
   * Times out after _maxBackendWaitTimeSeconds if backend doesn't respond
   */
  void _startTimerUpdates() {
    if (_periodicTimerStarted) return; // Timer already started
    _periodicTimerStarted = true;
    _waitCount = 0; // Reset wait counter

    _timerUpdateTimer?.cancel(); // Cancel any existing timer

    _timerUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final timerModel = Provider.of<TimerModel>(context, listen: false);

      // Wait for backend to respond - timer not active yet
      if (!timerModel.isTimerForChallenge(widget.challengeId)) {
        _waitCount++;
        if (_waitCount > _maxBackendWaitTimeSeconds) {
          // If backend didn't respond in time, cancel timer and don't show it
          timer.cancel();
          _periodicTimerStarted = false;
          setState(() {
            hasTimer = false;
            timeLeft = "--:--";
            currentTime = 0.0;
          });
          print(
              "Timer start timeout: Backend didn't respond within $_maxBackendWaitTimeSeconds seconds. isActive=${timerModel.isActive}, currentChallengeId=${timerModel.currentChallengeId}");
          displayToast(
              "Timer failed to start. Please try again.", Status.error);
          return;
        }
        // Wait for backend to respond
        return;
      }

      // Backend responded, reset wait counter and start displaying
      _waitCount = 0;

      final timeRemaining = timerModel.getTimeRemaining();

      if (timeRemaining == null || timeRemaining <= 0) {
        timer.cancel();
        _periodicTimerStarted = false;
        setState(() {
          hasTimer = false;
          timeLeft = "00:00";
          currentTime = 0.0;
        });
        // Tell backend timer expired; backend sends TimerCompletedDto via stream, which will trigger _handleTimerExpiration() and make Time's Up modal appear
        timerModel.completeTimer(widget.challengeId);
        return;
      }

      final minutes = (timeRemaining / 60).floor();
      final seconds = timeRemaining % 60;
      final minutesStr = minutes.toString().padLeft(2, '0');
      final secondsStr = seconds.toString().padLeft(2, '0');

      // Start flashing when 5 seconds left: flash twice then stay on
      if (timeRemaining <= 5 && !_hasStartedFlashing) {
        _hasStartedFlashing = true;
        setState(() => _showWarningColors = true);
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) setState(() => _showWarningColors = false);
        });
        Future.delayed(Duration(milliseconds: 600), () {
          if (mounted) setState(() => _showWarningColors = true);
        });
        Future.delayed(Duration(milliseconds: 900), () {
          if (mounted) setState(() => _showWarningColors = false);
        });
        Future.delayed(Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _showWarningColors = true);
        });
      }

      setState(() {
        timeLeft = "$minutesStr:$secondsStr";
        currentTime = timeRemaining.toDouble();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcon();
    streamStarted = startPositionStream();
    setStartingHintCircle();

    // Listen to compass events for marker rotation
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() {
          _compassHeading = event.heading!;
        });
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

    // Timer: Set up listeners first (before sending requests)
    _setupTimerStartedListener(); // Listen for timer started from backend
    _setupTimerExpirationListener(); // Listen for timer expiration from backend
    _setupTimerExtensionListener(); // Listen for timer extension from backend
    _setupTimerWarningListener(); // Listen for timer warning from backend
    // Initialize timer state (this sends request to backend)
    _initializeTimer();
  }

  /**
   * Initialize timer state for the current challenge / reset timer state
   * Only sets hasTimer = true if challenge actually has a timerLength > 0
   */
  void _initializeTimer() {
    setState(() {
      hasTimer = false;
      timeLeft = "--:--";
      currentTime = 0.0;
      totalTime = 0;
      _periodicTimerStarted = false;
      _waitCount = 0;
      _showWarningColors = false;
      _hasStartedFlashing = false;
    });

    // Cancel any existing timer
    _timerUpdateTimer?.cancel();

    // Check if this challenge has a timer
    final challengeModel = Provider.of<ChallengeModel>(context, listen: false);
    final challenge = challengeModel.getChallengeById(widget.challengeId);
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    final onboarding = Provider.of<OnboardingModel>(context, listen: false);

    if (challenge?.timerLength != null && challenge!.timerLength! > 0) {
      setState(() {
        hasTimer = true;
        totalTime = challenge.timerLength!;
      });

      // DON'T start timer if user is still in onboarding (step 5 is the gameplay intro overlay)
      // Timer will start naturally when user navigates to challenge after completing onboarding
      if (!onboarding.step5GameplayIntroComplete) {
        print(
            "Timer not started for challenge ${widget.challengeId} - onboarding not complete");
        return;
      }

      // Request backend to start timer (sends StartChallengeTimerDto)
      timerModel.startTimer(widget.challengeId);

      // Start periodic timer, which won't display until backend responds
      _startTimerUpdates();
    } else {
      print(
          "No timer for challenge ${widget.challengeId} (timerLength=${challenge?.timerLength})");
    }
  }

  /**
   * Listens for timer started (TimerStartedDto) from backend
   * Calculates totalTime as: originalTimerLength + (extensionsUsed * EXTENSION_TIME_SECONDS)
   * This ensures progress = remainingTime / totalAllocatedTime
   */
  void _setupTimerStartedListener() {
    final client = Provider.of<ApiClient>(context, listen: false);

    // cancel any existing subscription
    _timerStartedSubscription?.cancel();

    _timerStartedSubscription =
        client.clientApi.timerStartedStream.listen((event) {
      if (event.challengeId == widget.challengeId && mounted) {
        final timerModel = Provider.of<TimerModel>(context, listen: false);
        final timeRemaining = timerModel.getTimeRemaining();
        final challengeModel =
            Provider.of<ChallengeModel>(context, listen: false);
        final challenge = challengeModel.getChallengeById(widget.challengeId);

        if (challenge?.timerLength != null &&
            timeRemaining != null &&
            timeRemaining > 0) {
          setState(() {
            // If timer has been extended, show progress relative to EXTENSION_TIME_SECONDS (5 min)
            // This ensures the circle shows correct progress when coming back after logout
            // Otherwise use original timer length
            totalTime = event.extensionsUsed > 0
                ? EXTENSION_TIME_SECONDS
                : challenge!.timerLength!;
            currentTime = timeRemaining.toDouble();
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(GameplayMap oldWidget) {
    // If challenge changed, reset hint state and timer state
    if (oldWidget.challengeId != widget.challengeId) {
      // Save whether modal/dialog was showing before removing it
      // If showing, user is navigating away (to failed/completed page)
      final wasTimerModalShowing = _timerModalShowing;
      final wasArrivedDialogShowing = _arrivedDialogShowing;

      startingHintCenter = null;
      hintCenter = null;
      hintRadius = null;
      setStartingHintCircle();

      // Remove timer modal if showing
      _removeTimerModal();

      // DON'T start timer for new challenge if any modal/dialog was showing
      // (user is about to navigate away to completion/failed page)
      if (!wasTimerModalShowing && !wasArrivedDialogShowing) {
        _initializeTimer();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _removeBearOverlay();
    _removeTimerModal();
    _removeTimerWarning();
    _compassSubscription?.cancel();
    positionStream.cancel();
    _disposeController();
    _timerUpdateTimer?.cancel(); // Cancel periodic timer updates
    _periodicTimerStarted = false;
    _waitCount = 0; //reset wait counter
    _timerCompletedSubscription?.cancel(); //cancel timer completion listener
    _timerExtendedSubscription?.cancel(); //cancel timer extension listener
    _timerWarningSubscription?.cancel(); //cancel timer warning listener
    _timerStartedSubscription?.cancel(); //cancel timer started listener
    _extensionAnimationController
        ?.dispose(); //dispose extension animation controller
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
    if (!mounted) {
      return false;
    }

    try {
      final location = await GeoPoint.current();
      if (!mounted) {
        return false;
      }
      setState(() {
        currentLocation = location;
      });

      // Immediately center the camera on the user's location
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.lat, location.long),
            zoom: 16.5,
          ),
        ),
      );

      positionStream = Geolocator.getPositionStream(
              locationSettings: GeoPoint.getLocationSettings())
          .listen((Position? newPos) {
        if (!mounted) {
          return;
        }
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
        if (!mounted) {
          return;
        }
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
    if (!mounted) {
      return;
    }

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
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
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

        //re-initialize timer if challenge data loads after initState
        if (challenge != null && !hasTimer && totalTime == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                challenge.timerLength != null &&
                challenge.timerLength! > 0) {
              _initializeTimer();
            }
          });
        }

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
                    rotation: _compassHeading,
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
            // Only show timer if challenge has a timer
            if (hasTimer)
              Positioned(
                top: MediaQuery.of(context).size.height *
                    0.02, // Adjust top position
                // left: MediaQuery.of(context).size.width * 0.5, // Adjust left position
                child: Container(
                  margin: EdgeInsets.all(4), // 4px margin on all sides
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      //timer container
                      Container(
                        width: MediaQuery.of(context).size.width * 0.20,
                        height: MediaQuery.of(context).size.height * 0.04,
                        decoration: BoxDecoration(
                          color: _showWarningColors
                              ? Color.fromARGB(204, 0, 0, 0)
                              : (currentTime < 300
                                  ? Color.fromARGB(
                                      255, 237, 86, 86) // red when < 5 min left
                                  : Color.fromARGB(
                                      255, 64, 64, 61)), // grey > 5 min left
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(
                                  64, 0, 0, 0), // #000000 with 25% opacity
                              blurRadius: 4,
                              offset: Offset(0, 4), // Position (0, 4)
                            ),
                          ],
                        ),
                      ),
                      // Timer icon and countdown centered
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center the row contents
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Timer icon (circular progress indicator)
                          Container(
                            margin: EdgeInsets.only(
                                right: 8), // 8px margin between icon and text
                            child: CustomPaint(
                              size: Size(20, 20), // Outer circle: 20px x 20px
                              painter: CircleSliceTimer(
                                  progress: totalTime > 0
                                      ? currentTime / totalTime
                                      : 0.0,
                                  iconColor: _showWarningColors
                                      ? Color(0xFFFF8080) // #FF8080
                                      : Colors.white),
                            ),
                          ),
                          // Countdown text
                          Text(
                            timeLeft,
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: _showWarningColors
                                    ? Color(0xFFFF8080)
                                    : Colors.white,
                                decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    // Stop timer when challenge is successfully completed
                    // This prevents "Time's Up" modal from appearing while congratulations dialog is showing
                    _timerUpdateTimer?.cancel();
                    _periodicTimerStarted = false;
                    setState(() {
                      hasTimer = false;
                    });
                  }
                  final chalId = widget.challengeId;
                  // Track that dialog is showing (prevents timer from starting for next challenge)
                  _arrivedDialogShowing = true;
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
                    // Re-enable the button and clear dialog flag after the dialog is closed
                    setState(() {
                      isArrivedButtonEnabled = true;
                      _arrivedDialogShowing = false;
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

  /** Formats time remaining in seconds to fit warning message (e.g., "5 minutes", "1 minute", "30 seconds") */
  String _formatTimeRemaining(int seconds) {
    if (seconds >= 60) {
      // round to nearest minute to ensure "5 minutes" doesn't show up as "4 minutes" due to delay
      final minutes = ((seconds + 30) / 60).floor();
      return minutes == 1 ? "1 minute" : "$minutes minutes";
    } else {
      return "$seconds seconds";
    }
  }

  /** Listens for timer warning (TimerWarningDto) from backend and displays bear popup
   * - shows a popup animation of Niki warning the user of how much time is left 
   * - auto-dismisses after 1 second
   */
  void _setupTimerWarningListener() {
    final client = Provider.of<ApiClient>(context, listen: false);

    _timerWarningSubscription?.cancel();

    _timerWarningSubscription =
        client.clientApi.timerWarningStream.listen((event) {
      if (event.challengeId == widget.challengeId && mounted) {
        final timeLeft = _formatTimeRemaining(event.milestone);
        _displayTimerWarning(timeLeft);
      }
    });
  }

  /**
   * Listens for timer expiration (TimerCompletedDto) from backend and then calls _handleTimerExpiration
   */
  void _setupTimerExpirationListener() {
    final client = Provider.of<ApiClient>(context, listen: false);

    // cancel any existing subscriptions
    _timerCompletedSubscription?.cancel();

    _timerCompletedSubscription =
        client.clientApi.timerCompletedStream.listen((event) {
      if (event.challengeId == widget.challengeId &&
          mounted &&
          !_timerModalShowing) {
        _timerModalShowing = true;

        _handleTimerExpiration();
      } else {}
    });
  }

  /**
   * Listens for timer extension (TimerExtendedDto) from backend and updates timer display
   * Adds EXTENSION_TIME_SECONDS to totalTime so progress shows remaining / total allocated time
   */
  void _setupTimerExtensionListener() {
    final client = Provider.of<ApiClient>(context, listen: false);

    // cancel any existing subscriptions
    _timerExtendedSubscription?.cancel();

    _timerExtendedSubscription =
        client.clientApi.timerExtendedStream.listen((event) {
      if (event.challengeId == widget.challengeId && mounted) {
        // update timer display when timer is extended
        final timerModel = Provider.of<TimerModel>(context, listen: false);
        final timeRemaining = timerModel.getTimeRemaining();

        setState(() {
          hasTimer = true;
          // Set totalTime to EXTENSION_TIME_SECONDS (5 min) so progress circle
          // represents time remaining out of the extension time
          if (timeRemaining != null) {
            currentTime = timeRemaining.toDouble();
            totalTime = EXTENSION_TIME_SECONDS;
          }
          // reset warning colors when timer is extended
          _showWarningColors = false;
          _hasStartedFlashing = false;
        });
        // restart timer updates if they were stopped
        if (!_periodicTimerStarted) {
          _startTimerUpdates();
        }
      }
    });
  }

  /**
   * Handles timer expiration in frontend - shows "Time's Up" modal 
   * Note: challenge is NOT completed
   */
  void _handleTimerExpiration() {
    if (!mounted || _timerModalShowing != true) {
      return;
    }

    _timerUpdateTimer?.cancel();
    _periodicTimerStarted = false;

    // Start animation for extension choice countdown
    _extensionAnimationController?.dispose();
    _extensionAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _extensionChoiceWindowSeconds),
    );
    _extensionAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _extensionAnimationController!,
        curve: Curves.linear,
      ),
    );

    // Listen to animation updates to rebuild overlay
    _extensionAnimationController!.addListener(() {
      if (mounted && _timerModalShowing && _timerModalOverlay != null) {
        _timerModalOverlay!.markNeedsBuild();
      }
    });

    // Start the animation
    _extensionAnimationController!.forward();

    // Add Time's Up overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_timerModalShowing) return;

      _timerModalOverlay = OverlayEntry(
        opaque: false,
        builder: (overlayContext) => Stack(
          children: [
            // Dimmed game map as background for modal overlay
            GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Center(
              child: _buildTimesUpModal(),
            ),
          ],
        ),
      );

      Overlay.of(context).insert(_timerModalOverlay!);
    });
  }

  void _removeTimerModal() {
    if (_timerModalOverlay != null) {
      try {
        _timerModalOverlay?.remove();
        _timerModalOverlay?.dispose();
      } catch (e) {
        debugPrint("Error removing timer modal overlay: $e");
      }
      _timerModalOverlay = null;
    }
    _extensionAnimationController?.dispose();
    _extensionAnimationController = null;
    _extensionAnimation = null;
    _timerModalShowing = false;
  }

  /**
   * Builds the "Time's Up" modal dialog with Results and Extension buttons
   */
  Widget _buildTimesUpModal() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          padding: EdgeInsets.only(
            top: screenHeight * 0.019, //~16px
            bottom: screenHeight * 0.028, //~24px
            left: screenWidth * 0.041, //~16px
            right: screenWidth * 0.041, //~16px
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // SVG image
              SvgPicture.asset(
                'assets/images/niki_head_sweat.svg',
                alignment: Alignment.center,
              ),
              // Title
              Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.005), //~5px
                child: Text(
                  "Time's Up!",
                  style: TextStyle(
                    fontSize: screenWidth * 0.061, //~24px
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              // Message
              Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.019), //~16px
                child: Text(
                  "Want more time? Earn 5 more minutes of exploring for ${(widget.points * 0.25).floor()} points!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.036, //~14px
                    color: Colors.black,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Results button (width 86px, height 40px)
                  SizedBox(
                    width: screenWidth * 0.210, // ~82px
                    height: screenHeight * 0.047, // ~40px on 852px screen
                    child: ElevatedButton(
                      onPressed: () {
                        final timerModel =
                            Provider.of<TimerModel>(context, listen: false);
                        final client =
                            Provider.of<ApiClient>(context, listen: false);

                        // Listen for challengeFailed event from backend, then navigate
                        late StreamSubscription<ChallengeFailedDto>
                            subscription;
                        subscription = client.clientApi.challengeFailedStream
                            .listen((event) {
                          if (event.challengeId == widget.challengeId) {
                            subscription.cancel();

                            // Remove overlay before navigating
                            if (_timerModalOverlay != null) {
                              _timerModalOverlay?.remove();
                              _timerModalOverlay?.dispose();
                              _timerModalOverlay = null;
                            }
                            _timerModalShowing = false;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChallengeFailedPage(
                                  challengeId: widget.challengeId,
                                ),
                              ),
                            );
                          }
                        });

                        // Tell backend to immediately fail the challenge (skip grace period)
                        timerModel.completeTimer(widget.challengeId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side:
                            BorderSide(color: Color.fromARGB(255, 237, 86, 86)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              screenWidth * 0.025), //~10px
                        ),
                      ),
                      child: Text(
                        "Results",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: screenWidth * 0.036, //~14px
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 237, 86, 86),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.033), //~13px
                  // Extension button (width 200px, height 40px) with sliding color indicator
                  SizedBox(
                    width: screenWidth * 0.478, // ~187px
                    height: screenHeight * 0.047, // ~40px
                    child: Stack(
                      children: [
                        // Base container with faded color (full size, always visible)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF08988), // Faded color
                              borderRadius: BorderRadius.circular(
                                  screenWidth * 0.025), //~10px
                            ),
                          ),
                        ),
                        // Overlay with normal red color that shrinks from right to left
                        if (_extensionAnimationController?.status !=
                            AnimationStatus.completed)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    screenWidth * 0.025), //~10px
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor:
                                        _extensionAnimation?.value ?? 0.0,
                                    child: Container(
                                      color: Color.fromARGB(
                                          255, 237, 86, 86), // Normal red
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: ElevatedButton(
                            onPressed: _extensionAnimationController?.status ==
                                    AnimationStatus.completed
                                ? () {
                                    displayToast(
                                        "Sorry, time has run out to choose the extension. Please click Results.",
                                        Status.error);
                                  }
                                : () async {
                                    final success = await _extendTimer();
                                    if (success) {
                                      _removeTimerModal(); // Close modal if timer extended successfully; otherwise leave open for user to return home/retry extending timer
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.only(
                                left: screenWidth * 0.010, //~4px
                                right: screenWidth * 0.020, //~8px
                                top: screenHeight * 0.011, //~9px
                                bottom: screenHeight * 0.011, //~9px
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    screenWidth * 0.025), //~10px
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("+ 5 Min for ",
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: screenWidth * 0.033, //~13px
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                SvgPicture.asset('assets/icons/bearcoins.svg',
                                    width: screenWidth * 0.041, //~16px
                                    height: screenWidth * 0.041),
                                Flexible(
                                  child: Text(
                                      " ${(widget.points * 0.25).floor()} Pt",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: screenWidth * 0.033, //~13px
                                          color: Color(0xFFFFC737))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Extends the timer - requests extensions from backend
   * Returns true if extension succeeds (timer is extended by 5 minutes), false if it fails
   */
  Future<bool> _extendTimer() async {
    final timerModel = Provider.of<TimerModel>(context, listen: false);

    // Get current end time and extend timer
    final currentEndTime = timerModel.endTime;
    if (currentEndTime == null) {
      displayToast("Unable to extend timer", Status.error);
      return false;
    }

    // Extend timer by 5 minutes (300 seconds)
    final newEndTime = currentEndTime.add(Duration(seconds: 300));
    final errorMessage =
        await timerModel.extendTimer(widget.challengeId, newEndTime);

    if (errorMessage != null) {
      // Check if it's specifically an insufficient coins error
      if (errorMessage.toLowerCase().contains('insufficient coins') ||
          errorMessage.toLowerCase().contains('cannot extend timer')) {
        displayToast(
            "Unable to extend timer: Insufficient coins", Status.error);
      } else {
        // Other timer-related errors
        displayToast("Unable to extend timer: $errorMessage", Status.error);
      }
      return false;
    }

    // Success - timerExtended event will update the timer automatically via stream
    // The stream listener (_setupTimerExtensionListener) handles resetting totalTime and currentTime
    setState(() {
      hasTimer = true;
    });
    return true;
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

/**
 * CircleSliceTimer creates the circular icon timer for a challenge.
 * The timer starts out as a fully white circle, and slices of the timer are cut out as time progresses in the challenge.
 * */
class CircleSliceTimer extends CustomPainter {
  final double progress;
  final Color iconColor;

  CircleSliceTimer({required this.progress, this.iconColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer circle of timer icon
    Paint outerCirclePaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.38;

    canvas.drawCircle(center, size.width / 2, outerCirclePaint);

    final innerRadius = 7.0;

    // Draw white background circle first (full circle - remaining time)
    Paint whiteCirclePaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, whiteCirclePaint);

    // Draw gray arc on top showing elapsed time (grows clockwise from top)
    // Elapsed progress = 1.0 - progress (how much time has passed)
    double elapsedProgress = 1.0 - progress;
    if (elapsedProgress > 0) {
      Paint grayArcPaint = Paint()
        ..color = Color.fromARGB(255, 64, 64, 61)
        ..style = PaintingStyle.fill;

      double sweepAngle = 2 * pi * elapsedProgress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -pi / 2,
        sweepAngle,
        true,
        grayArcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
