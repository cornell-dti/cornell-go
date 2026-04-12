import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/constants/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

Future<BitmapDescriptor> _bitmapDescriptorFromSvgAsset(
  BuildContext context,
  String assetPath, {
  double width = 50,
  double height = 53,
}) async {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final loader = SvgAssetLoader(assetPath);
  final PictureInfo info = await vg.loadPicture(loader, context);
  ui.Picture? composed;
  ui.Image? image;
  try {
    final src = info.size;
    if (src.width <= 0 || src.height <= 0) {
      throw StateError(
          '_bitmapDescriptorFromSvgAsset: invalid PictureInfo.size');
    }

    final outW = (width * dpr).round().clamp(1, 4096);
    final outH = (height * dpr).round().clamp(1, 4096);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(outW / src.width, outH / src.height);
    canvas.drawPicture(info.picture);
    composed = recorder.endRecording();

    image = await composed.toImage(outW, outH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError(
          '_bitmapDescriptorFromSvgAsset: toByteData returned null');
    }
    return BitmapDescriptor.bytes(
      byteData.buffer.asUint8List(),
      width: width,
      height: height,
      bitmapScaling: MapBitmapScaling.auto,
    );
  } finally {
    image?.dispose();
    composed?.dispose();
    info.picture.dispose();
  }
}

enum EventPinState {
  later,
  soon,
  now,
}

class _ExampleMapPin {
  final String id;
  final LatLng position;
  final int categoryIndex;
  final EventPinState state;

  const _ExampleMapPin({
    required this.id,
    required this.position,
    required this.categoryIndex,
    required this.state,
  });
}

String _pinStateColorName(EventPinState state) => switch (state) {
      EventPinState.later => 'green',
      EventPinState.soon => 'yellow',
      EventPinState.now => 'red',
    };

String _pinAssetPath(int categoryIndex, EventPinState state) {
  final color = _pinStateColorName(state);
  final base = switch (categoryIndex) {
    0 => 'burger_pin',
    1 => 'fund_pin',
    2 => 'mic_pin',
    3 => 'speaker_pin',
    _ => 'burger_pin',
  };
  return 'assets/icons/${base}_$color.svg';
}

String _pinIconKey(int categoryIndex, EventPinState state) =>
    '${categoryIndex}_${state.name}';

String _selectedPinAssetPath(EventPinState state) =>
    'assets/icons/selected_pin_${_pinStateColorName(state)}.svg';

String _selectedPinIconKey(EventPinState state) => 'selected_${state.name}';

const Map<String, ui.Size> _kPinSvgViewBox = {
  'burger_pin_green.svg': ui.Size(62, 58),
  'burger_pin_yellow.svg': ui.Size(66, 58),
  'burger_pin_red.svg': ui.Size(62, 58),
  'fund_pin_green.svg': ui.Size(62, 58),
  'fund_pin_yellow.svg': ui.Size(66, 58),
  'fund_pin_red.svg': ui.Size(66, 58),
  'mic_pin_green.svg': ui.Size(66, 58),
  'mic_pin_yellow.svg': ui.Size(66, 58),
  'mic_pin_red.svg': ui.Size(66, 58),
  'speaker_pin_green.svg': ui.Size(62, 58),
  'speaker_pin_yellow.svg': ui.Size(66, 58),
  'speaker_pin_red.svg': ui.Size(66, 58),
  'selected_pin_green.svg': ui.Size(52, 77),
  'selected_pin_yellow.svg': ui.Size(52, 77),
  'selected_pin_red.svg': ui.Size(52, 77),
};

ui.Size _pinRasterSize(String assetPath, double scaleMultiplier) {
  final name = assetPath.split('/').last;
  final vb = _kPinSvgViewBox[name] ?? const ui.Size(62, 58);
  final selected = name.startsWith('selected_pin_');
  final refW = selected ? 52.0 : 62.0;
  final refH = selected ? 77.0 : 58.0;
  final targetW = selected ? 60.0 : 50.0;
  final targetH = selected ? 71.0 : 53.0;
  final sw = targetW / refW;
  final sh = targetH / refH;
  final refScale = selected ? (sw > sh ? sw : sh) : (sw < sh ? sw : sh);
  final s = refScale * scaleMultiplier;
  return ui.Size(vb.width * s, vb.height * s);
}

const _kExamplePins = <_ExampleMapPin>[
  _ExampleMapPin(
    id: 'e1',
    position: LatLng(42.4482, -76.4880),
    categoryIndex: 0,
    state: EventPinState.later,
  ),
  _ExampleMapPin(
    id: 'e2',
    position: LatLng(42.4465, -76.4865),
    categoryIndex: 0,
    state: EventPinState.soon,
  ),
  _ExampleMapPin(
    id: 'e3',
    position: LatLng(42.4475, -76.4890),
    categoryIndex: 0,
    state: EventPinState.now,
  ),
  _ExampleMapPin(
    id: 'e4',
    position: LatLng(42.4490, -76.4870),
    categoryIndex: 1,
    state: EventPinState.later,
  ),
  _ExampleMapPin(
    id: 'e5',
    position: LatLng(42.4455, -76.4855),
    categoryIndex: 1,
    state: EventPinState.now,
  ),
  _ExampleMapPin(
    id: 'e6',
    position: LatLng(42.4470, -76.4900),
    categoryIndex: 2,
    state: EventPinState.soon,
  ),
  _ExampleMapPin(
    id: 'e7',
    position: LatLng(42.4485, -76.4860),
    categoryIndex: 2,
    state: EventPinState.later,
  ),
  _ExampleMapPin(
    id: 'e8',
    position: LatLng(42.4460, -76.4885),
    categoryIndex: 3,
    state: EventPinState.now,
  ),
  _ExampleMapPin(
    id: 'e9',
    position: LatLng(42.4495, -76.4865),
    categoryIndex: 3,
    state: EventPinState.soon,
  ),
];

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage>
    with SingleTickerProviderStateMixin {
  int? _selectedCategoryIndex;

  String? _selectedMapPinId;

  List<Map<String, BitmapDescriptor>>? _pinIconsByScale;

  late final AnimationController _pinBounceController;

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

  static const double _kInitialCameraNorthOffsetLat = 0.001;

  static LatLng _cameraTargetBiasedNorth(LatLng userPosition) => LatLng(
        userPosition.latitude + _kInitialCameraNorthOffsetLat,
        userPosition.longitude,
      );

  static LatLng get _mapInitialCameraTarget =>
      _cameraTargetBiasedNorth(_mapDefaultCenter);

  static const double _kHomeMapZoom = 16;

  final Completer<GoogleMapController> _mapCompleter =
      Completer<GoogleMapController>();
  GeoPoint? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  BitmapDescriptor _currentLocationIcon = BitmapDescriptor.defaultMarker;

  static const int _kUserLocationMarkerLogicalPx = 72;
  double _compassHeading = 0;

  bool _followUserCamera = false;

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

  Set<Marker> _mergedMarkersForMap() {
    final pins = _markersForSelectedCategory();
    final at = _currentLocation == null
        ? _mapDefaultCenter
        : LatLng(_currentLocation!.lat, _currentLocation!.long);
    return {
      ...pins,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPinIcons());
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
    final pins = _pinsMatchingFilter();
    if (pins.isEmpty) return;
    _pinBounceController.duration = const Duration(milliseconds: 300);
    _pinBounceController.forward(from: 0);
  }

  List<_ExampleMapPin> _pinsMatchingFilter() {
    return [
      for (final pin in _kExamplePins)
        if (_selectedCategoryIndex == null ||
            pin.categoryIndex == _selectedCategoryIndex)
          pin,
    ];
  }

  Future<void> _putPinBitmapInTier(
    Map<String, BitmapDescriptor> tierMap,
    String path,
    String key,
    double scaleMul,
  ) async {
    final sz = _pinRasterSize(path, scaleMul);
    tierMap[key] = await _bitmapDescriptorFromSvgAsset(
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
        for (var cat = 0; cat < 4; cat++) {
          for (final state in EventPinState.values) {
            final path = _pinAssetPath(cat, state);
            await _putPinBitmapInTier(
              tierMap,
              path,
              _pinIconKey(cat, state),
              m,
            );
          }
        }
        for (final state in EventPinState.values) {
          if (!mounted) return;
          final path = _selectedPinAssetPath(state);
          await _putPinBitmapInTier(
            tierMap,
            path,
            _selectedPinIconKey(state),
            m,
          );
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

  Set<Marker> _markersForSelectedCategory() {
    final pins = _pinsMatchingFilter();
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
              ? _selectedPinIconKey(pin.state)
              : _pinIconKey(pin.categoryIndex, pin.state)]!,
          anchor: _selectedMapPinId == pin.id
              ? const Offset(0.5, 0.96)
              : const Offset(0.5, 0.52),
          zIndex: _selectedMapPinId == pin.id ? 3 : 2,
          onTap: () {
            setState(() => _selectedMapPinId = pin.id);
            unawaited(_animateCameraToBiased(pin.position));
            _runPinBounce();
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
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
              markers: _mergedMarkersForMap(),
              onTap: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                final hadSelection = _selectedMapPinId != null;
                setState(() => _selectedMapPinId = null);
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
                  const _HomeMapSearchBarExpandable(),
                  SizedBox(height: dH * 0.01),
                  _CategoryChipsRow(
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

class _HomeMapSearchBarExpandable extends StatefulWidget {
  const _HomeMapSearchBarExpandable();

  @override
  State<_HomeMapSearchBarExpandable> createState() =>
      _HomeMapSearchBarExpandableState();
}

class _HomeMapSearchBarExpandableState
    extends State<_HomeMapSearchBarExpandable> {
  bool _expanded = false;
  String? _distance = '5 min';
  String? _time;
  String? _date;

  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() => setState(() {});

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() => _expanded = !_expanded);
  }

  ColorFilter? get _filterIconColorFilter {
    if (_searchFocus.hasFocus) {
      return const ColorFilter.mode(AppColors.grayText, BlendMode.srcIn);
    }
    if (_expanded) {
      return const ColorFilter.mode(AppColors.purple, BlendMode.srcIn);
    }
    return const ColorFilter.mode(AppColors.black30, BlendMode.srcIn);
  }

  @override
  Widget build(BuildContext context) {
    final searchFocused = _searchFocus.hasFocus;
    final dH = MediaQuery.sizeOf(context).height;
    final barH = dH * 0.055;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          width: 1,
          color: searchFocused ? AppColors.lightGray : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: searchFocused ? AppColors.black20 : AppColors.black10,
            blurRadius: searchFocused ? 16 : 10,
            offset: Offset(0, searchFocused ? 6 : 4),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: barH,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TextField(
                    focusNode: _searchFocus,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    textAlignVertical: TextAlignVertical.center,
                    cursorWidth: 1.5,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: AppColors.grayText,
                    ),
                    cursorColor: AppColors.darkText,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixIcon: Icon(
                        Icons.search,
                        color: searchFocused
                            ? AppColors.darkText
                            : AppColors.black30,
                        size: 20,
                      ),
                      hintText: searchFocused
                          ? null
                          : 'Search a name, location, etc...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: AppColors.black30,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 50,
                      height: 36,
                      child: Center(
                        child: InkResponse(
                          onTap: _toggleFilter,
                          radius: 22,
                          child: SvgPicture.asset(
                            'assets/icons/Group 578.svg',
                            width: 32,
                            height: 32,
                            colorFilter: _filterIconColorFilter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.lightGrayBorder,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FilterColumn(
                        title: 'Distance',
                        children: [
                          _FilterCheckboxRow(
                            label: '5 min',
                            value: _distance == '5 min',
                            onChanged: (v) =>
                                setState(() => _distance = v ? '5 min' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '15 min',
                            value: _distance == '15 min',
                            onChanged: (v) =>
                                setState(() => _distance = v ? '15 min' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '20+ min',
                            value: _distance == '20+ min',
                            onChanged: (v) => setState(
                                () => _distance = v ? '20+ min' : null),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _FilterColumn(
                        title: 'Time',
                        children: [
                          _FilterCheckboxRow(
                            label: 'Current',
                            value: _time == 'Current',
                            onChanged: (v) =>
                                setState(() => _time = v ? 'Current' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '30 mins',
                            value: _time == '30 mins',
                            onChanged: (v) =>
                                setState(() => _time = v ? '30 mins' : null),
                          ),
                          _FilterCheckboxRow(
                            label: '1+ hour',
                            value: _time == '1+ hour',
                            onChanged: (v) =>
                                setState(() => _time = v ? '1+ hour' : null),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _FilterColumn(
                        title: 'Date',
                        children: [
                          _FilterCheckboxRow(
                            label: 'Today',
                            value: _date == 'Today',
                            onChanged: (v) =>
                                setState(() => _date = v ? 'Today' : null),
                          ),
                          _FilterCheckboxRow(
                            label: 'Tomorrow',
                            value: _date == 'Tomorrow',
                            onChanged: (v) =>
                                setState(() => _date = v ? 'Tomorrow' : null),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: InkWell(
                              onTap: () => setState(() => _date = 'Custom'),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: _date == 'Custom'
                                          ? AppColors.purple
                                          : AppColors.grayText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Custom',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        color: _date == 'Custom'
                                            ? AppColors.purple
                                            : AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ElevatedButton(
                  onPressed: () => setState(() => _expanded = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterColumn extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FilterColumn({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _FilterCheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.purple,
                side: const BorderSide(color: AppColors.borderGray, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: value ? AppColors.purple : AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final int? selectedIndex;
  final ValueChanged<int> onCategorySelected;

  static const _chips = <_CategoryChipData>[
    _CategoryChipData(label: 'Food', iconAsset: 'assets/icons/burger.svg'),
    _CategoryChipData(label: 'Swag', iconAsset: 'assets/icons/fund.svg'),
    _CategoryChipData(label: 'Concerts', iconAsset: 'assets/icons/mic.svg'),
    _CategoryChipData(label: 'Speakers', iconAsset: 'assets/icons/speaker.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _CategoryChipsScrollClipper(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
          child: Row(
            children: [
              for (var i = 0; i < _chips.length; i++) ...[
                _CategoryChip(
                  data: _chips[i],
                  selected: selectedIndex != null && i == selectedIndex,
                  onTap: () => onCategorySelected(i),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChipsScrollClipper extends CustomClipper<Path> {
  const _CategoryChipsScrollClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTRB(-16, -8, size.width, size.height + 20));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CategoryChipData {
  final String label;
  final String iconAsset;

  const _CategoryChipData({required this.label, required this.iconAsset});
}

class _CategoryChip extends StatelessWidget {
  final _CategoryChipData data;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(end: selected ? 1 : 0),
      builder: (_, t, __) {
        final fg = Color.lerp(AppColors.mediumGray, AppColors.purple, t)!;
        final bc = Color.lerp(Colors.transparent, AppColors.purple, t)!;
        return Material(
          color: Colors.transparent,
          clipBehavior: Clip.none,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: bc, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black10,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    data.iconAsset,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
