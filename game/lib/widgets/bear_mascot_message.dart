import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * `BearMascotMessage` Widget - Displays the bear mascot with a message bubble.
 *
 * @remarks
 * Used in the onboarding flow to show the bear mascot with explanatory messages.
 * Also used in the timer flow to show the bear mascot with warning messages of how much time is left.
 * Responsive design that adapts to different screen sizes.
 * Uses simple percentage-based positioning from edges of the screen.
 * Full-screen tappable area captures taps anywhere on the widget.
 *
 * @param message - The text message to display in the bubble
 * @param showBear - Whether to show the bear mascot (default: true)
 * @param bearAsset - Which bear asset to use: 'standing' or 'popup' (default: 'standing')
 * @param bearLeftPercent - Bear position from left edge (0.0 = left, 1.0 = right)
 * @param bearBottomPercent - Bear position from bottom edge (0.0 = bottom, 1.0 = top)
 * @param messageLeftPercent - Message position from left edge (0.5 = centered)
 * @param messageBottomPercent - Message position from bottom edge (0.0 = bottom, 1.0 = top)
 * @param onTap - Optional callback when user taps anywhere on the widget
 * @param textStyle - Optional custom text style for the message (default: gray, regular weight)
 * @param messageBoxWidthPercent - Optional custom width for message box as percentage of screen width (default: 0.677)
 */
class BearMascotMessage extends StatelessWidget {
  final String message;
  final bool showBear;
  final String bearAsset;
  final double bearLeftPercent; // 0.0 = left edge, 1.0 = right edge
  final double bearBottomPercent; // 0.0 = bottom edge, 1.0 = top edge
  final double messageLeftPercent;
  final double messageBottomPercent; // 0.0 = bottom edge, 1.0 = top edge
  final VoidCallback? onTap; // Optional tap callback for the entire widget
  final TextStyle? textStyle; // Optional custom text style
  final double? messageBoxWidthPercent; // Optional custom message box width

  const BearMascotMessage({
    Key? key,
    required this.message,
    this.showBear = true,
    this.bearAsset = 'standing',
    this.bearLeftPercent = 0.1,
    this.bearBottomPercent = 0.15,
    this.messageLeftPercent = 0.5,
    this.messageBottomPercent = 0.4,
    this.onTap,
    this.textStyle,
    this.messageBoxWidthPercent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on Figma design (393x852)
    final messageBoxWidth = screenWidth * (messageBoxWidthPercent ?? 0.677);
    final bearWidth =
        bearAsset == 'popup' ? screenWidth * 0.509 : screenWidth * 0.437;
    final bearHeight =
        bearAsset == 'popup' ? screenHeight * 0.317 : screenHeight * 0.272;
    final arrowWidth = screenWidth * 0.102;
    final arrowHeight = screenHeight * 0.056;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          clipBehavior: Clip.none, // Allow children to render beyond bounds
          children: [
            // Bear positioned using simple percentages
            if (showBear)
              Positioned(
                left: screenWidth * bearLeftPercent,
                bottom: screenHeight * bearBottomPercent,
                child: Image.asset(
                  bearAsset == 'popup'
                      ? 'assets/images/bear_popup.png'
                      : 'assets/images/bear_standing.png',
                  width: bearWidth,
                  height: bearHeight,
                  fit: BoxFit.contain,
                ),
              ),
            // Message positioned using simple percentages
            Positioned(
              left: screenWidth * messageLeftPercent -
                  (messageBoxWidth / 2), // Center the box
              bottom: screenHeight * messageBottomPercent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: messageBoxWidth,
                    constraints: BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 21, vertical: 20),
                    child: Text(
                      message,
                      style: textStyle ??
                          const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E6E6E),
                            height: 1.5,
                            decoration: TextDecoration.none,
                          ),
                    ),
                  ),
                  // Speech bubble tail pointing down-left toward bear
                  Transform.translate(
                    offset: Offset(
                      -messageBoxWidth * 0.35,
                      -arrowHeight * 0.4,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/bubblearrow.svg',
                      width: arrowWidth,
                      height: arrowHeight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
