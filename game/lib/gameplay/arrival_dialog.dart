import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/gameplay/challenge_completed.dart';
import 'package:game/quiz/quiz_page.dart';
import 'package:game/constants/constants.dart';

/// Widget that displays the arrival dialog for challenges
/// Handles both hasArrived and !hasArrived states
class ArrivalDialog extends StatelessWidget {
  final bool hasArrived;
  final String challengeId;
  final String? challengeName;

  const ArrivalDialog({
    Key? key,
    required this.hasArrived,
    required this.challengeId,
    this.challengeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!hasArrived) {
      return _NotArrivedDialog();
    }

    return Consumer4<ApiClient, EventModel, TrackerModel, GroupModel>(
      builder: (context, apiClient, eventModel, trackerModel, groupModel, _) {
        return _ArrivedDialog(
          challengeId: challengeId,
          challengeName: challengeName,
          apiClient: apiClient,
          eventModel: eventModel,
          trackerModel: trackerModel,
          groupModel: groupModel,
        );
      },
    );
  }
}

/// Dialog shown when user hasn't arrived yet
class _NotArrivedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Keep going! You're getting closer."),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown when user has arrived at the challenge location
class _ArrivedDialog extends StatelessWidget {
  final String challengeId;
  final String? challengeName;
  final ApiClient apiClient;
  final EventModel eventModel;
  final TrackerModel trackerModel;
  final GroupModel groupModel;

  const _ArrivedDialog({
    Key? key,
    required this.challengeId,
    this.challengeName,
    required this.apiClient,
    required this.eventModel,
    required this.trackerModel,
    required this.groupModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = challengeName ?? "";

    return Container(
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Text(
              "You've arrived at ${name}!",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            child: SvgPicture.asset(
              'assets/images/arrived.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Check quiz availability for all cases
          FutureBuilder<QuizProgressDto?>(
            future: _checkQuizAvailability(apiClient, challengeId),
            builder: (context, snapshot) {
              final hasQuiz = snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.totalQuestions > 0;

              return _ButtonRow(
                challengeId: challengeId,
                hasQuiz: hasQuiz,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Check if challenge has quiz questions available
  Future<QuizProgressDto?> _checkQuizAvailability(
    ApiClient apiClient,
    String challengeId,
  ) async {
    final completer = Completer<QuizProgressDto?>();
    late StreamSubscription subscription;

    subscription = apiClient.clientApi.quizProgressStream.listen((progress) {
      if (progress.challengeId == challengeId && !completer.isCompleted) {
        completer.complete(progress);
      }
    });

    // Request quiz progress
    apiClient.serverApi?.getQuizProgress(
      RequestQuizQuestionDto(challengeId: challengeId),
    );

    // Wait for response or timeout
    try {
      final result = await completer.future.timeout(
        Duration(seconds: 2),
        onTimeout: () => null,
      );
      await subscription.cancel();
      return result;
    } catch (e) {
      await subscription.cancel();
      return null;
    }
  }
}

/// Reusable button row widget for arrival dialog
class _ButtonRow extends StatelessWidget {
  final String challengeId;
  final bool hasQuiz;

  const _ButtonRow({
    Key? key,
    required this.challengeId,
    required this.hasQuiz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChallengeCompletedPage(challengeId: challengeId),
                ),
              );
            },
            style: ButtonStyle(
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(
                  horizontal:
                      (MediaQuery.devicePixelRatioOf(context) < 3 ? 6 : 10),
                ),
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    7.3,
                  ), // Adjust the radius as needed
                ),
              ),
              side: MaterialStateProperty.all<BorderSide>(
                BorderSide(
                  color: AppColors.primaryRed, // Specify the border color
                  width: 2.0, // Specify the border width
                ),
              ),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Point Breakdown",
                style: TextStyle(
                  fontSize:
                      MediaQuery.devicePixelRatioOf(context) < 3 ? 12 : 14,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ),
        ),
        // Show quiz button if quiz exists
        if (hasQuiz) ...[
          const SizedBox(width: 10),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(challengeId: challengeId),
                  ),
                );
              },
              icon: SvgPicture.asset(
                'assets/icons/bearcoins.svg',
                height: 20,
                width: 20,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "+10 PTS",
                  style: TextStyle(
                    fontSize:
                        MediaQuery.devicePixelRatioOf(context) < 3 ? 12 : 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: ButtonStyle(
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.devicePixelRatioOf(context) < 3 ? 6 : 10,
                  ),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.3),
                  ),
                ),
                backgroundColor: MaterialStateProperty.all<Color>(
                  AppColors.primaryRed,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
