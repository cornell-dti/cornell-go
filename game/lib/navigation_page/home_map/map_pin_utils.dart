import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' as svg;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:game/navigation_page/home_map/home_map_categories.dart';

/**
 * Map Pin Utilities - Icon rasterization + pin asset helpers.
 *
 * This file contains the shared utilities for converting SVG pin assets into
 * `BitmapDescriptor`s (Google Maps markers) and the small helpers that map
 * category/state → asset path/key.
 *
 * @remarks
 * These utilities are used by `HomeMapPage` to build a cache of marker icons
 * for multiple animation scale tiers (bounce animation).
 */

enum EventPinState {
  later,
  soon,
  now,
}

// Placeholder pin model (temporary until API data).
class ExampleMapPin {
  final String id;
  final LatLng position;
  final int categoryIndex;
  final EventPinState state;

  const ExampleMapPin({
    required this.id,
    required this.position,
    required this.categoryIndex,
    required this.state,
  });
}

// Maps a pin state to its semantic color name in assets.
String pinStateColorName(EventPinState state) => switch (state) {
      EventPinState.later => 'green',
      EventPinState.soon => 'yellow',
      EventPinState.now => 'red',
    };

// Pin SVG asset path for a category + state.
String pinAssetPath(int categoryIndex, EventPinState state) {
  final color = pinStateColorName(state);
  final base = (categoryIndex >= 0 && categoryIndex < homeMapCategories.length)
      ? homeMapCategories[categoryIndex].pinBaseAsset
      : homeMapCategories.first.pinBaseAsset;
  return 'assets/icons/${base}_$color.svg';
}

// Cache key for an unselected pin icon.
String pinIconKey(int categoryIndex, EventPinState state) =>
    '${categoryIndex}_${state.name}';

// Returns the selected-pin SVG asset path for a given state.
String selectedPinAssetPath(int categoryIndex, EventPinState state) {
  final base = (categoryIndex >= 0 && categoryIndex < homeMapCategories.length)
      ? homeMapCategories[categoryIndex].selectedPinBaseAsset
      : homeMapCategories.first.selectedPinBaseAsset;
  final color = pinStateColorName(state);
  return 'assets/icons/${base}_$color.svg';
}

// Cache key for a selected pin icon.
String selectedPinIconKey(int categoryIndex, EventPinState state) =>
    'selected_${categoryIndex}_${state.name}';

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
  'selected_fund_pin_green.svg': ui.Size(64, 78),
  'selected_fund_pin_yellow.svg': ui.Size(64, 78),
  'selected_fund_pin_red.svg': ui.Size(64, 78),
  'selected_mic_pin_green.svg': ui.Size(64, 78),
  'selected_mic_pin_yellow.svg': ui.Size(64, 78),
  'selected_mic_pin_red.svg': ui.Size(64, 78),
  'selected_speaker_pin_green.svg': ui.Size(64, 78),
  'selected_speaker_pin_yellow.svg': ui.Size(64, 78),
  'selected_speaker_pin_red.svg': ui.Size(64, 78),
};

//Computes the rasterization size for a pin SVG.
ui.Size pinRasterSize(String assetPath, double scaleMultiplier) {
  final name = assetPath.split('/').last;
  final vb = _kPinSvgViewBox[name] ?? const ui.Size(62, 58);
  final selected = name.startsWith('selected_');
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

// SVG asset → `BitmapDescriptor` (marker icon).
Future<BitmapDescriptor> bitmapDescriptorFromSvgAsset(
  BuildContext context,
  String assetPath, {
  required double width,
  required double height,
}) async {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final loader = svg.SvgAssetLoader(assetPath);
  final svg.PictureInfo info = await svg.vg.loadPicture(loader, context);

  ui.Picture? composed;
  ui.Image? image;
  try {
    final src = info.size;
    if (src.width <= 0 || src.height <= 0) {
      throw StateError(
          'bitmapDescriptorFromSvgAsset: invalid PictureInfo.size');
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
          'bitmapDescriptorFromSvgAsset: toByteData returned null');
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
