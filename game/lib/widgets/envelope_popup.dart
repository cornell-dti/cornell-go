import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * `EnvelopePopup` Widget - Bear envelope popup with configurable text.
 *
 * @remarks
 * - Header line 1 is fixed: "DON'T MISS OUT ON"
 * - If `buttonLabel` is "Turn On Notifications" and `onButtonPressed` is null,
 *   the CTA opens the device app settings.
 *
 * @param titleText - Header line 2
 * @param envelopeText - Text shown inside the envelope
 * @param buttonLabel - CTA label
 * @param onButtonPressed - Optional CTA handler
 * @param onClose - Optional cancel handler
 */
class EnvelopePopup extends StatelessWidget {
  const EnvelopePopup({
    super.key,
    required this.titleText,
    required this.envelopeText,
    required this.buttonLabel,
    this.onButtonPressed,
    this.onClose,
  });

  final String titleText;
  final String envelopeText;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onClose;

  static const String _settingsButtonLabel = 'Turn On Notifications';
  static const String _headerLine1 = "DON'T MISS OUT ON";
  static const double _illustrationWidth = 180;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
      alignment: const Alignment(0, -0.6),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkResponse(
                    onTap: () {
                      onClose?.call();
                      Navigator.of(context).maybePop();
                    },
                    radius: 20,
                    child: SvgPicture.asset(
                      'assets/icons/cancel.svg',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        Colors.black38,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _PopupHeader(
                  line1: _headerLine1,
                  line2: titleText,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _illustrationWidth,
                  ),
                  child: _BearEnvelopeGraphic(envelopeText: envelopeText),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (onButtonPressed != null) {
                        onButtonPressed!.call();
                        return;
                      }

                      if (buttonLabel.trim() == _settingsButtonLabel) {
                        await AppSettings.openAppSettings();
                        return;
                      }

                      Navigator.of(context).maybePop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF7A5A73),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BearEnvelopeGraphic extends StatelessWidget {
  const _BearEnvelopeGraphic({required this.envelopeText});

  final String envelopeText;
  static const double _envelopeTextRotationRad = -(2 * 3.14 / 180);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (296 / 177);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/icons/bear_popup.svg',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, -0.58),
                  child: FractionallySizedBox(
                    widthFactor: 0.62,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Transform.rotate(
                        angle: _envelopeTextRotationRad,
                        child: Text(
                          envelopeText.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFE94C4C),
                            letterSpacing: 1.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader({required this.line1, required this.line2});

  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          line1,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            fontFamily: 'Poppins',
            color: const Color(0xFF1E1E1E),
          ),
        ),
        Text(
          line2,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 36,
            fontFamily: 'Poppins',
            height: 1.1,
            letterSpacing: 0.4,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}

// Shows an `EnvelopePopup` dialog.
Future<void> showEnvelopePopup(
  BuildContext context, {
  required String titleText,
  required String envelopeText,
  required String buttonLabel,
  VoidCallback? onButtonPressed,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.12),
    barrierDismissible: true,
    builder: (context) => EnvelopePopup(
      titleText: titleText,
      envelopeText: envelopeText,
      buttonLabel: buttonLabel,
      onButtonPressed: onButtonPressed,
    ),
  );
}
