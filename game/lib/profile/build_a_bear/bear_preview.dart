import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';

/// A reusable widget that renders a layered bear preview.
///
/// Displays the bear's color (base), eyes, mouth, and accessory layers
/// with per-asset scale and offset adjustments so the bear looks the same
/// everywhere it appears (profile page, build-a-bear editor, etc.).
///
/// Pass [bearWidth] and [bearHeight] for sizing, and [itemForSlot] to
/// resolve each [BearSlotDto] to the [BearItemDto] that should be shown
/// (or `null` for no item in that slot).
class BearPreview extends StatelessWidget {
  const BearPreview({
    Key? key,
    required this.bearWidth,
    required this.bearHeight,
    required this.itemForSlot,
  }) : super(key: key);

  /// Logical width of the bear area.
  final double bearWidth;

  /// Logical height of the bear area.
  final double bearHeight;

  /// Returns the [BearItemDto] to render for the given slot, or `null`.
  final BearItemDto? Function(BearSlotDto slot) itemForSlot;

  @override
  Widget build(BuildContext context) {
    final eyesOffsetY = -bearHeight * 0.19;
    final mouthOffsetY = -bearHeight * 0.135;

    return SizedBox(
      width: bearWidth,
      height: bearHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0 – Color (base)
          _buildColorLayer(),
          // Layer 1 – Eyes
          _buildEyesLayer(eyesOffsetY),
          // Layer 2 – Mouth
          _buildMouthLayer(mouthOffsetY),
          // Layer 3 – Accessory
          _buildAccessoryLayer(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Color layer
  // ---------------------------------------------------------------------------

  Widget _buildColorLayer() {
    final colorItem = itemForSlot(BearSlotDto.COLOR);
    if (colorItem != null) {
      return Image.asset(
        'assets/${colorItem.assetKey}.png',
        fit: BoxFit.contain,
      );
    }
    return Image.asset(
      'assets/icons/bearnaked.png',
      fit: BoxFit.contain,
    );
  }

  // ---------------------------------------------------------------------------
  // Eyes layer
  // ---------------------------------------------------------------------------

  Widget _buildEyesLayer(double defaultOffsetY) {
    final eyesItem = itemForSlot(BearSlotDto.EYES);
    if (eyesItem == null) return const SizedBox.shrink();

    final isBlush = eyesItem.assetKey == 'buildabear/eyes/blush';
    final isEmbarrassed = eyesItem.assetKey == 'buildabear/eyes/embarrassed';
    final eyeScale = (isBlush || isEmbarrassed) ? 0.35 : 0.24;
    final eyesXOffset = isEmbarrassed ? bearWidth * 0.04 : 0.0;
    final eyesYOffset = isEmbarrassed
        ? defaultOffsetY - bearHeight * 0.02
        : defaultOffsetY;

    return Center(
      child: Transform.translate(
        offset: Offset(eyesXOffset, eyesYOffset),
        child: SizedBox(
          width: bearWidth * eyeScale,
          height: bearHeight * eyeScale,
          child: Image.asset(
            'assets/${eyesItem.assetKey}.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mouth layer
  // ---------------------------------------------------------------------------

  Widget _buildMouthLayer(double defaultOffsetY) {
    final mouthItem = itemForSlot(BearSlotDto.MOUTH);
    if (mouthItem == null) return const SizedBox.shrink();

    final isCheeks = mouthItem.assetKey == 'buildabear/mouth/cheeks';
    final isGrin = mouthItem.assetKey == 'buildabear/mouth/grin';
    final isSmirk = mouthItem.assetKey == 'buildabear/mouth/smirk';
    final isNervous = mouthItem.assetKey == 'buildabear/mouth/nervous';
    final isTongue = mouthItem.assetKey == 'buildabear/mouth/tongue';
    final isSerious = mouthItem.assetKey == 'buildabear/mouth/serious';
    final isUwu = mouthItem.assetKey == 'buildabear/mouth/uwu';

    final mouthScale = (isCheeks || isGrin || isSmirk)
        ? 0.16
        : (isNervous || isSerious || isUwu ? 0.12 : 0.1);
    final mouthXOffset = isGrin
        ? -bearWidth * 0.01
        : (isSmirk ? bearWidth * 0.01 : 0.0);
    final mouthYOffset = (isNervous || isTongue)
        ? defaultOffsetY + bearHeight * 0.02
        : (isGrin ? defaultOffsetY + bearHeight * 0.01 : defaultOffsetY);

    return Center(
      child: Transform.translate(
        offset: Offset(mouthXOffset, mouthYOffset),
        child: SizedBox(
          width: bearWidth * mouthScale,
          height: bearHeight * mouthScale,
          child: Image.asset(
            'assets/${mouthItem.assetKey}.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Accessory layer
  // ---------------------------------------------------------------------------

  Widget _buildAccessoryLayer() {
    final accItem = itemForSlot(BearSlotDto.ACCESSORY);
    if (accItem == null) return const SizedBox.shrink();

    final key = accItem.assetKey;

    double accessoryScale = 0.2;
    double accXOffset = 0.0;
    double accYOffset = 0.0;

    if (key == 'buildabear/accessories/bow') {
      accessoryScale = 0.2;
      accXOffset = bearWidth * 0.0;
      accYOffset = -bearHeight * 0.0;
    } else if (key == 'buildabear/accessories/bowtie') {
      accessoryScale = 0.25;
      accXOffset = bearWidth * 0.0;
      accYOffset = -bearHeight * 0.025;
    } else if (key == 'buildabear/accessories/flower') {
      accessoryScale = 0.2;
      accXOffset = bearWidth * 0.2;
      accYOffset = -bearHeight * 0.26;
    } else if (key == 'buildabear/accessories/glasses') {
      accessoryScale = 0.4;
      accXOffset = bearWidth * 0.0;
      accYOffset = -bearHeight * 0.18;
    } else if (key == 'buildabear/accessories/goatee') {
      accessoryScale = 0.35;
      accXOffset = bearWidth * 0.0;
      accYOffset = -bearHeight * 0.08;
    } else if (key == 'buildabear/accessories/necktie') {
      accessoryScale = 0.2;
      accXOffset = bearWidth * 0.0;
      accYOffset = bearHeight * 0.05;
    } else if (key == 'buildabear/accessories/purse') {
      accessoryScale = 0.25;
      accXOffset = bearWidth * 0.48;
      accYOffset = bearHeight * 0.17;
    } else if (key == 'buildabear/accessories/scarf') {
      accessoryScale = 0.7;
      accXOffset = bearWidth * 0.0;
      accYOffset = -bearHeight * 0.0;
    } else if (key == 'buildabear/accessories/tophat') {
      accessoryScale = 0.25;
      accXOffset = bearWidth * 0.0;
      accYOffset = -bearHeight * 0.38;
    }

    return Center(
      child: Transform.translate(
        offset: Offset(accXOffset, accYOffset),
        child: SizedBox(
          width: bearWidth * accessoryScale,
          height: bearHeight * accessoryScale,
          child: Image.asset(
            'assets/${accItem.assetKey}.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
