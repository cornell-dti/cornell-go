import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/constants/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:game/model/campus_event_model.dart';

import 'package:game/navigation_page/events_draggable_sheet.dart';
import 'package:game/navigation_page/home_map/category_chips.dart';
import 'package:game/navigation_page/home_map/home_map_categories.dart';
import 'package:game/navigation_page/home_map/home_map_search_bar.dart';
import 'package:game/navigation_page/home_map/map_pin_utils.dart';

/**
 * Home Map Page - Primary "Home" tab map experience.
 *
 * This page owns Google Maps setup, location/compass subscriptions, and the
 * pin marker animation/cache. UI overlay widgets (search + category chips)
 * are split into dedicated files under `navigation_page/home_map/`.
 */

class _CampusEventMapPin {
  final String id;
  final LatLng position;
  final int categoryIndex;
  final EventPinState state;

  const _CampusEventMapPin({
    required this.id,
    required this.position,
    required this.categoryIndex,
    required this.state,
  });
}

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage>
    with SingleTickerProviderStateMixin {
  // Overlay state (category selection / pin selection)
  int? _selectedCategoryIndex;

  String? _selectedMapPinId;
  String? _goToEventId;

  // Pin icon cache for animated bounce tiers
  List<Map<String, BitmapDescriptor>>? _pinIconsByScale;

  late final AnimationController _pinBounceController;

  // Discrete scale multipliers for the bounce animation.
  static const List<double> _scaleMultipliers = [
    0.91,
    0.935,
    0.96,
    0.985,
    1.01,
    1.03,
    1.045,
    1.018,
    1.0,
  ];

  static const LatLng _mapDefaultCenter = LatLng(42.447, -76.4875);

  // Initial camera bias
  static const double _kInitialCameraNorthOffsetLat = 0.001;

  static LatLng _cameraTargetBiasedNorth(LatLng userPosition) => LatLng(
        userPosition.latitude + _kInitialCameraNorthOffsetLat,
        userPosition.longitude,
      );

  static LatLng get _mapInitialCameraTarget =>
      _cameraTargetBiasedNorth(_mapDefaultCenter);

  static const double _kHomeMapZoom = 16;

  // Google Map controller + live sensors
  final Completer<GoogleMapController> _mapCompleter =
      Completer<GoogleMapController>();
  GeoPoint? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  BitmapDescriptor _currentLocationIcon = BitmapDescriptor.defaultMarker;

  static const int _kUserLocationMarkerLogicalPx = 72;
  double _compassHeading = 0;

  // When true, the camera keeps tracking user updates.
  bool _followUserCamera = false;

  // Marker bounce animation
  double _bounceScale(double t) {
    final x = t.clamp(0.0, 1.0);
    const med = 0.94;
    const peak = 1.045;
    const rest = 1.0;
    const split = 0.5;
    if (x <= split) {
      final u = Curves.easeInOutCubic.transform(x / split);
      return ui.lerpDouble(med, peak, u)!;
    }
    final u = Curves.easeInOutCubic.transform((x - split) / (1.0 - split));
    return ui.lerpDouble(peak, rest, u)!;
  }

  int _nearestScaleIndex(double scale) {
    var bestI = 0;
    var bestD = (_scaleMultipliers[0] - scale).abs();
    for (var i = 1; i < _scaleMultipliers.length; i++) {
      final d = (_scaleMultipliers[i] - scale).abs();
      if (d < bestD) {
        bestD = d;
        bestI = i;
      }
    }
    return bestI;
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: width,
    );
    final fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _setCustomUserLocationIcon() async {
    const w = _kUserLocationMarkerLogicalPx;
    final markerBytes =
        await _getBytesFromAsset('assets/icons/userlocation.png', w);
    if (!mounted) return;
    setState(() {
      _currentLocationIcon = BitmapDescriptor.bytes(
        markerBytes,
        width: w.toDouble(),
        height: w.toDouble(),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapCompleter.isCompleted) {
      _mapCompleter.complete(controller);
    }
    _startHomePositionStream();
  }

  CameraUpdate _homeCameraUpdate(LatLng target) =>
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _cameraTargetBiasedNorth(target),
          zoom: _kHomeMapZoom,
        ),
      );

  // Animate the map to the home camera config.
  Future<void> _animateHomeCameraTo(
    LatLng target, {
    required bool followUser,
  }) async {
    _followUserCamera = followUser;
    if (!_mapCompleter.isCompleted) return;
    final controller = await _mapCompleter.future;
    if (!mounted) return;
    await controller.animateCamera(_homeCameraUpdate(target));
    if (mounted) setState(() {});
  }

  Future<void> _recenterOnUser() async {
    final loc = _currentLocation;
    if (loc == null) return;
    await _animateHomeCameraTo(
      LatLng(loc.lat, loc.long),
      followUser: true,
    );
  }

  Future<void> _animateCameraToBiased(LatLng focus) async {
    await _animateHomeCameraTo(focus, followUser: false);
  }

  Future<void> _goToEvent(CampusEventDto event) async {
    setState(() {
      _selectedCategoryIndex = null;
      _selectedMapPinId = event.id;
      _goToEventId = event.id;
    });
    await _animateCameraToBiased(LatLng(event.latitude, event.longitude));
    _runPinBounce();
  }

  Future<void> _startHomePositionStream() async {
    if (_positionSubscription != null) return;
    final GoogleMapController controller = await _mapCompleter.future;
    if (!mounted) return;
    try {
      final location = await GeoPoint.current();
      if (!mounted) return;
      setState(() => _currentLocation = location);
    } catch (e) {
      debugPrint('HomeMap: initial location failed: $e');
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: GeoPoint.getLocationSettings(),
    ).listen(
      (Position? newPos) {
        if (!mounted) return;
        if (newPos == null) {
          _currentLocation = GeoPoint(
            _mapDefaultCenter.latitude,
            _mapDefaultCenter.longitude,
            0,
          );
        } else {
          _currentLocation = GeoPoint(
            newPos.latitude,
            newPos.longitude,
            newPos.heading,
          );
        }
        if (_followUserCamera) {
          final loc = _currentLocation!;
          controller.animateCamera(
            _homeCameraUpdate(LatLng(loc.lat, loc.long)),
          );
        }
        setState(() {});
      },
    );
  }

  DateTime? _parseEventTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso.toLocal();
    try {
      return HttpDate.parse(trimmed).toLocal();
    } catch (_) {
      return null;
    }
  }

  EventPinState _pinStateForEvent(CampusEventDto event) {
    final now = DateTime.now();
    final start = _parseEventTime(event.startTime);
    final end = _parseEventTime(event.endTime);
    if (start != null && end != null && start.isBefore(now) && end.isAfter(now)) {
      return EventPinState.now;
    }
    if (start == null) return EventPinState.later;
    final diff = start.difference(now);
    if (!diff.isNegative && diff <= const Duration(hours: 3)) {
      return EventPinState.soon;
    }
    return EventPinState.later;
  }

  int _mapCategoryIndex(CampusEventDto event) {
    final category = event.categories.isNotEmpty
        ? event.categories.first
        : CampusEventCategoriesDto.OTHER;
    switch (category) {
      case CampusEventCategoriesDto.SOCIAL:
      case CampusEventCategoriesDto.CULTURAL:
        return 1; // Concerts
      case CampusEventCategoriesDto.ARTS:
      case CampusEventCategoriesDto.ACADEMIC:
      case CampusEventCategoriesDto.CAREER:
        return 2; // Speakers
      case CampusEventCategoriesDto.COMMUNITY:
      case CampusEventCategoriesDto.OTHER:
        return 3; // Fundraisers
      case CampusEventCategoriesDto.ATHLETIC:
      case CampusEventCategoriesDto.WELLNESS:
        return 0; // Food bucket (fallback)
    }
  }

  List<CampusEventDto> _activeCampusEvents(CampusEventModel campusEventModel) {
    return campusEventModel.currentList?.events ?? campusEventModel.allCachedEvents;
  }

  bool _hasPhysicalLocation(CampusEventDto event) {
    final location = event.locationName.trim();
    final hasNamedLocation = location.isNotEmpty &&
        location.toLowerCase() != 'virtual' &&
        location.toLowerCase() != 'online';
    final hasCoords = event.latitude.isFinite &&
        event.longitude.isFinite &&
        !(event.latitude == 0 && event.longitude == 0);
    return hasNamedLocation && hasCoords;
  }

  List<_CampusEventMapPin> _pinsMatchingFilter(List<CampusEventDto> events) {
    final now = DateTime.now();
    final pins = <_CampusEventMapPin>[];
    for (final event in events) {
      if (!_hasPhysicalLocation(event)) continue;
      final end = _parseEventTime(event.endTime);
      if (end != null && end.isBefore(now)) continue;

      final pin = _CampusEventMapPin(
        id: event.id,
        position: LatLng(event.latitude, event.longitude),
        categoryIndex: _mapCategoryIndex(event),
        state: _pinStateForEvent(event),
      );
      if (_selectedCategoryIndex == null ||
          _selectedCategoryIndex == pin.categoryIndex) {
        pins.add(pin);
      }
    }
    return pins;
  }

  Set<Marker> _mergedMarkersForMap(List<CampusEventDto> events) {
    final pins = _markersForSelectedCategory(events);
    final at = _currentLocation == null
        ? _mapDefaultCenter
        : LatLng(_currentLocation!.lat, _currentLocation!.long);
    return {
      ...pins,
      // Current user marker.
      Marker(
        markerId: const MarkerId('currentLocation'),
        icon: _currentLocationIcon,
        position: at,
        anchor: const Offset(0.5, 0.5),
        rotation: _compassHeading,
        zIndex: 0,
        onTap: () => unawaited(_animateCameraToBiased(at)),
      ),
    };
  }

  CampusEventDto? _selectedGoToEvent(List<CampusEventDto> events) {
    final id = _goToEventId;
    if (id == null) return null;
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  Set<Polyline> _routePolyline(List<CampusEventDto> events) {
    final selectedEvent = _selectedGoToEvent(events);
    final userLoc = _currentLocation;
    if (selectedEvent == null || userLoc == null) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('event_route'),
        color: AppColors.purple,
        width: 5,
        geodesic: true,
        patterns: <PatternItem>[
          PatternItem.dash(20),
          PatternItem.gap(12),
        ],
        points: [
          LatLng(userLoc.lat, userLoc.long),
          LatLng(selectedEvent.latitude, selectedEvent.longitude),
        ],
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _pinBounceController = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _setCustomUserLocationIcon();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() => _compassHeading = event.heading!);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CampusEventModel>().requestCampusEvents(limit: 50);
      _loadPinIcons();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _pinBounceController.dispose();
    super.dispose();
  }

  void _runPinBounce() {
    if (_pinIconsByScale == null) return;
    final campusEventModel = context.read<CampusEventModel>();
    final pins = _pinsMatchingFilter(_activeCampusEvents(campusEventModel));
    if (pins.isEmpty) return;
    _pinBounceController.duration = const Duration(milliseconds: 300);
    _pinBounceController.forward(from: 0);
  }

  Future<void> _putPinBitmapInTier(
    Map<String, BitmapDescriptor> tierMap,
    String path,
    String key,
    double scaleMul,
  ) async {
    final sz = pinRasterSize(path, scaleMul);
    tierMap[key] = await bitmapDescriptorFromSvgAsset(
      context,
      path,
      width: sz.width,
      height: sz.height,
    );
  }

  Future<void> _loadPinIcons() async {
    if (!mounted) return;
    try {
      final byScale = <Map<String, BitmapDescriptor>>[];
      for (final m in _scaleMultipliers) {
        if (!mounted) return;
        final tierMap = <String, BitmapDescriptor>{};
        for (var cat = 0; cat < homeMapCategories.length; cat++) {
          for (final state in EventPinState.values) {
            final path = pinAssetPath(cat, state);
            await _putPinBitmapInTier(
              tierMap,
              path,
              pinIconKey(cat, state),
              m,
            );
          }
        }
        final selectedByPath = <String, BitmapDescriptor>{};
        for (var cat = 0; cat < homeMapCategories.length; cat++) {
          for (final state in EventPinState.values) {
            if (!mounted) return;
            final path = selectedPinAssetPath(cat, state);
            final key = selectedPinIconKey(cat, state);
            final cached = selectedByPath[path];
            if (cached != null) {
              tierMap[key] = cached;
            } else {
              await _putPinBitmapInTier(tierMap, path, key, m);
              selectedByPath[path] = tierMap[key]!;
            }
          }
        }
        byScale.add(tierMap);
      }
      if (!mounted) return;
      setState(() {
        _pinIconsByScale = byScale;
      });
      _runPinBounce();
    } catch (e, st) {
      debugPrint('HomeMap: pin SVG load failed: $e\n$st');
      if (!mounted) return;
      setState(() => _pinIconsByScale = null);
    }
  }

  Set<Marker> _markersForSelectedCategory(List<CampusEventDto> events) {
    final pins = _pinsMatchingFilter(events);
    if (pins.isEmpty) return {};
    final byScale = _pinIconsByScale;
    if (byScale == null) return {};

    final scale = _bounceScale(_pinBounceController.value);
    final tier = _nearestScaleIndex(scale);
    final icons = byScale[tier];
    return {
      for (final pin in pins)
        Marker(
          markerId: MarkerId('${pin.id}_$tier'),
          position: pin.position,
          icon: icons[_selectedMapPinId == pin.id
              ? selectedPinIconKey(pin.categoryIndex, pin.state)
              : pinIconKey(pin.categoryIndex, pin.state)]!,
          anchor: _selectedMapPinId == pin.id
              ? const Offset(0.5, 0.96)
              : const Offset(0.5, 0.52),
          zIndex: _selectedMapPinId == pin.id ? 3 : 2,
          onTap: () {
            setState(() {
              _selectedMapPinId = pin.id;
              _goToEventId = null;
            });
            unawaited(_animateCameraToBiased(pin.position));
            _runPinBounce();
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final campusEventModel = context.watch<CampusEventModel>();
    final campusEvents = _activeCampusEvents(campusEventModel);
    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _followUserCamera = false,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _mapInitialCameraTarget,
                zoom: _kHomeMapZoom,
              ),
              markers: _mergedMarkersForMap(campusEvents),
              polylines: _routePolyline(campusEvents),
              onTap: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                final hadSelection = _selectedMapPinId != null;
                setState(() {
                  _selectedMapPinId = null;
                  _goToEventId = null;
                });
                if (hadSelection) _runPinBounce();
              },
            ),
          ),
          _HomeMapOverlay(
            selectedCategoryIndex: _selectedCategoryIndex,
            onCategorySelected: (i) {
              setState(() {
                _selectedCategoryIndex = _selectedCategoryIndex == i ? null : i;
                _selectedMapPinId = null;
              });
              _runPinBounce();
            },
            onRecenter: _recenterOnUser,
          ),
          EventsDraggableSheet(
            onGoToEvent: _goToEvent,
            selectedEventId: _selectedMapPinId,
            routedEventId: _goToEventId,
            onClearSelection: () {
              setState(() {
                _selectedMapPinId = null;
                _goToEventId = null;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _HomeMapOverlay extends StatelessWidget {
  const _HomeMapOverlay({
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
    required this.onRecenter,
  });

  final int? selectedCategoryIndex;
  final ValueChanged<int> onCategorySelected;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    final dW = MediaQuery.sizeOf(context).width;
    final dH = MediaQuery.sizeOf(context).height;
    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: dW * 0.05,
            right: dW * 0.05,
            top: dH * 0.01,
            child: PointerInterceptor(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HomeMapSearchBarExpandable(),
                  SizedBox(height: dH * 0.01),
                  CategoryChipsRow(
                    selectedIndex: selectedCategoryIndex,
                    onCategorySelected: onCategorySelected,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 160,
            child: PointerInterceptor(
              child: _RecenterButton(onTap: onRecenter),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black20,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/maprecenter.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                AppColors.purple,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
