import 'package:flutter/material.dart';

/**
 * Helper to convert Figma design measurements to Flutter Alignment values
 * 
 * Figma design frame: 393 × 852px
 * 
 * Usage:
 * ```dart
 * Alignment bearPosition = FigmaAlignment.fromFigmaPosition(
 *   figmaX: 86,
 *   figmaY: 620,
 *   figmaFrameWidth: 393,
 *   figmaFrameHeight: 852,
 * );
 * ```
 */
class FigmaAlignment {
  // Standard Figma frame dimensions for Cornell Go design
  static const double designFrameWidth = 393.0;
  static const double designFrameHeight = 852.0;

  /**
   * Converts Figma pixel coordinates to Flutter Alignment
   * 
   * Figma coords: (0,0) = top-left, (width, height) = bottom-right
   * Flutter Alignment: (-1,-1) = top-left, (1,1) = bottom-right
   * 
   * @param figmaX - X position in pixels from Figma (0 = left edge)
   * @param figmaY - Y position in pixels from Figma (0 = top edge)
   * @param figmaFrameWidth - Width of Figma design frame
   * @param figmaFrameHeight - Height of Figma design frame
   */
  static Alignment fromFigmaPosition({
    required double figmaX,
    required double figmaY,
    double figmaFrameWidth = designFrameWidth,
    double figmaFrameHeight = designFrameHeight,
  }) {
    // Convert Figma pixel position (0-width, 0-height) to percentage (0-1)
    final xPercent = figmaX / figmaFrameWidth;
    final yPercent = figmaY / figmaFrameHeight;

    // Convert percentage to Alignment (-1 to 1)
    // Formula: alignment = (percent * 2) - 1
    final alignmentX = (xPercent * 2) - 1;
    final alignmentY = (yPercent * 2) - 1;

    return Alignment(alignmentX, alignmentY);
  }

  /**
   * Converts Figma percentage-based position to Alignment
   * 
   * Useful when you know the position as a percentage of the frame
   * 
   * @param xPercent - X position as percentage (0.0 = left, 1.0 = right)
   * @param yPercent - Y position as percentage (0.0 = top, 1.0 = bottom)
   */
  static Alignment fromPercentage({
    required double xPercent,
    required double yPercent,
  }) {
    final alignmentX = (xPercent * 2) - 1;
    final alignmentY = (yPercent * 2) - 1;

    return Alignment(alignmentX, alignmentY);
  }

  /**
   * Helper to position element at bottom with specific padding from bottom
   * 
   * @param pixelsFromBottom - Distance from bottom in Figma pixels
   * @param figmaFrameHeight - Height of Figma design frame
   * @param figmaFrameWidth - Width of Figma design frame
   */
  static Alignment bottomWithPadding({
    required double pixelsFromBottom,
    double figmaFrameHeight = designFrameHeight,
    double figmaFrameWidth = designFrameWidth,
  }) {
    // Calculate Y position: frameHeight - pixelsFromBottom
    final figmaY = figmaFrameHeight - pixelsFromBottom;
    return fromFigmaPosition(
      figmaX: figmaFrameWidth / 2, // centered horizontally
      figmaY: figmaY,
      figmaFrameWidth: figmaFrameWidth,
      figmaFrameHeight: figmaFrameHeight,
    );
  }
}
