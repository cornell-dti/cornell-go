import 'package:flutter/material.dart';

/// Placeholder stage, next step after journey creation 
class ChallengeCreationPage extends StatelessWidget {
  const ChallengeCreationPage({super.key, this.createdEventId});

  /// Server id of the `EventBase` with `isJourney == true`, if creation succeeded.
  final String? createdEventId;

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}
