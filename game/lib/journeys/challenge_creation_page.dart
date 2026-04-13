import 'package:flutter/material.dart';
import 'package:game/constants/constants.dart';

/// Next step after journey creation: add challenges (placeholder until wired).
class ChallengeCreationPage extends StatelessWidget {
  const ChallengeCreationPage({super.key, this.createdEventId});

  /// Server id of the `EventBase` with `isJourney == true`, if creation succeeded.
  final String? createdEventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add challenges',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Your journey was created. Next, add stops and challenges.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.darkText.withOpacity(0.85),
                ),
              ),
              if (createdEventId != null && createdEventId!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Event ID',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  createdEventId!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
