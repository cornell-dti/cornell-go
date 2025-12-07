import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/quiz_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/gameplay/challenge_completed.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:flutter/scheduler.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Entry widget for quiz page that uses the existing QuizModel
class QuizPage extends StatelessWidget {
  final String challengeId;

  const QuizPage({Key? key, required this.challengeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the existing QuizModel from the provider tree
    final quizModel = Provider.of<QuizModel>(context, listen: false);
    // Request question when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      quizModel.requestQuestion(challengeId);
    });

    return _QuizScreen(challengeId: challengeId);
  }
}

/// Main quiz UI screen
class _QuizScreen extends StatefulWidget {
  final String challengeId;

  const _QuizScreen({Key? key, required this.challengeId}) : super(key: key);

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  bool _hasShownResultDialog = false;

  @override
  void initState() {
    super.initState();
    // Reset the dialog flag when the quiz screen initializes
    _hasShownResultDialog = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizModel>(
      builder: (context, quizModel, _) {
        // Show result dialog immediately after submission (only for current challenge)
        if (quizModel.isSubmitted &&
            quizModel.lastResult != null &&
            quizModel.currentChallengeId == widget.challengeId &&
            !_hasShownResultDialog) {
          _hasShownResultDialog = true;
          Future.microtask(() => _showResultDialog(context, quizModel));
        }

        // Handle NO_QUESTIONS error by automatically navigating away
        if (quizModel.errorMessage != null &&
            quizModel.errorMessage!
                .toLowerCase()
                .contains('no available questions') &&
            !quizModel.isLoading) {
          // Check if this is a journey and navigate accordingly
          final eventModel = Provider.of<EventModel>(context, listen: false);
          final trackerModel =
              Provider.of<TrackerModel>(context, listen: false);
          final groupModel = Provider.of<GroupModel>(context, listen: false);

          final eventId = groupModel.curEventId;
          final event = eventModel.getEventById(eventId ?? "");
          final tracker = trackerModel.trackerByEventId(eventId ?? "");
          final isJourney = (event?.challenges?.length ?? 0) > 1;
          final journeyCompleted = isJourney &&
              tracker != null &&
              tracker.prevChallenges.length >= (event?.challenges?.length ?? 0);

          // Navigate away immediately
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
              if (isJourney && !journeyCompleted) {
                // Journey not completed - go to next challenge
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GameplayPage()),
                );
              } else {
                // Journey completed OR single challenge - show point breakdown
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChallengeCompletedPage(
                      challengeId: widget.challengeId,
                    ),
                  ),
                );
              }
            }
          });
          return const SizedBox.shrink();
        }

        // Show error if any (other than NO_QUESTIONS)
        if (quizModel.errorMessage != null &&
            !quizModel.errorMessage!
                .toLowerCase()
                .contains('no available questions') &&
            !quizModel.isLoading) {
          Future.microtask(() => _showErrorDialog(context, quizModel));
        }

        // Show loading indicator
        if (quizModel.isLoading && quizModel.currentQuestion == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F5F1),
            appBar: AppBar(
              backgroundColor: const Color(0xFFE95755),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Quiz', style: TextStyle(color: Colors.white)),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show error state if no question available
        if (quizModel.currentQuestion == null && !quizModel.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F5F1),
            appBar: AppBar(
              backgroundColor: const Color(0xFFE95755),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Quiz', style: TextStyle(color: Colors.white)),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No quiz questions available',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final question = quizModel.currentQuestion;
        if (question == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9F5F1),
          appBar: AppBar(
            backgroundColor: const Color(0xFFE95755),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Quiz', style: TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _questionCard(context, quizModel, question),
                  const SizedBox(height: 16),
                  _answerList(quizModel, question),
                ]),
              ),
              // Submit button at same position as Return Home button
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.sizeOf(context).height * 0.05,
                child: _submitBtn(quizModel),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Displays the current question with category, points, and shuffle button
  Widget _questionCard(
      BuildContext context, QuizModel quizModel, QuizQuestionDto question) {
    // Get category from question (if available) or fall back to event category
    EventCategoryDto? category;
    if (question.category != null) {
      try {
        category = EventCategoryDto.values.firstWhere(
          (e) => e.name == question.category,
        );
      } catch (e) {
        category = null;
      }
    }

    // Fall back to event category if question doesn't have one
    if (category == null) {
      final eventModel = Provider.of<EventModel>(context, listen: false);
      final challengeModel =
          Provider.of<ChallengeModel>(context, listen: false);
      final groupModel = Provider.of<GroupModel>(context, listen: false);

      final challenge = challengeModel.getChallengeById(question.challengeId);
      final eventId = challenge?.linkedEventId ?? groupModel.curEventId;
      final event = eventModel.getEventById(eventId ?? "");
      category = event?.category;
    }

    final categoryText =
        category != null ? friendlyCategory[category] ?? category.name : "Quiz";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and Points row at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category label on the left
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9EDDA),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  categoryText,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              // Points display on the right
              Row(children: [
                SvgPicture.asset('assets/icons/bearcoins.svg',
                    height: 18, width: 18),
                const SizedBox(width: 4),
                Text(
                  '${question.pointValue} PTS',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC17E19)),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          // Question text (left-aligned)
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
          // Shuffle button on bottom right
          if (quizModel.shufflesRemaining > 0 && !quizModel.isSubmitted) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => quizModel.shuffleQuestion(),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE95755)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text(
                  'Shuffle (${quizModel.shufflesRemaining})',
                  style: const TextStyle(
                      color: Color(0xFFE95755), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  /// Generates tappable list of answer options
  Widget _answerList(QuizModel quizModel, QuizQuestionDto question) {
    return Column(
      children: List.generate(question.answers.length, (idx) {
        final active = quizModel.selectedAnswerIndex == idx;
        return GestureDetector(
          onTap: () => quizModel.selectAnswer(idx),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFDDBE) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: active ? const Color(0xFFFFAA5B) : Colors.grey[300]!,
                  width: 1.5),
            ),
            child: Center(
              child: Text(
                question.answers[idx].answerText,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: active ? const Color(0xFFE95755) : Colors.black),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Submit button to finalize the answer
  Widget _submitBtn(QuizModel quizModel) {
    final enabled = quizModel.selectedAnswerIndex != null &&
        !quizModel.isSubmitted &&
        !quizModel.isLoading;
    return ElevatedButton(
      onPressed: enabled ? () => quizModel.submitAnswer() : null,
      style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFE95755).withOpacity(enabled ? 1 : 0.6),
          padding:
              const EdgeInsets.only(right: 15, left: 15, top: 10, bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: quizModel.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Submit',
                  style: TextStyle(
                      fontSize: 21,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFFFFFFF)),
                ),
              ],
            ),
    );
  }

  /// Modal that shows up after answer submission
  Future<void> _showResultDialog(
      BuildContext context, QuizModel quizModel) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final result = quizModel.lastResult;
    if (result == null) return;

    // Create confetti controller for correct answers
    final confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    await showDialog(
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        context: context,
        builder: (dialogContext) {
          // Check if this is a journey (multi-challenge event) and if it's completed
          final eventModel = Provider.of<EventModel>(context, listen: false);
          final trackerModel =
              Provider.of<TrackerModel>(context, listen: false);
          final groupModel = Provider.of<GroupModel>(context, listen: false);

          final eventId = groupModel.curEventId;
          final event = eventModel.getEventById(eventId ?? "");
          final tracker = trackerModel.trackerByEventId(eventId ?? "");
          final isJourney = (event?.challenges?.length ?? 0) > 1;

          // Check if journey is completed (all challenges done)
          final journeyCompleted = isJourney &&
              tracker != null &&
              tracker.prevChallenges.length >= (event?.challenges?.length ?? 0);

          final isCorrect = result.isCorrect;

          // Play confetti if correct
          if (isCorrect) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              confettiController.play();
            });
          }

          return Stack(
            children: [
              Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          // Dialog header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isCorrect ? 'Correct!' : 'Sorry…',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? const Color(0xFF58B171)
                                        : const Color(0xFFE95755)),
                              ),
                              InkWell(
                                  onTap: () {
                                    confettiController.stop();
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.close, size: 18))
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Body depending on correctness
                          if (isCorrect) ...[
                            const Text(
                              "Yay! You've earned points to\nmove up the leaderboard.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            // Large bearcoin icon and points display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/icons/bearcoins.svg',
                                    height: 40, width: 40),
                                Text(
                                  '+10 PTS',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(
                                          0xFFC17E19)), // Golden-brown color
                                ),
                              ],
                            ),
                          ] else ...[
                            RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 14),
                                    children: [
                                      const TextSpan(
                                          text: 'The correct answer was '),
                                      TextSpan(
                                          text: result.correctAnswerText,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const TextSpan(text: '.')
                                    ])),
                            const SizedBox(height: 12),
                            Image.asset('assets/images/cryingbear.png',
                                height: 80, width: 80),
                          ],

                          const SizedBox(height: 16),

                          // Navigation button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                confettiController.stop();
                                Navigator.pop(context);
                                // For journeys: if completed, show point breakdown; otherwise go to next challenge
                                // For single challenges: always show point breakdown
                                if (isJourney && !journeyCompleted) {
                                  // Journey not completed - go to next challenge
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GameplayPage(),
                                    ),
                                  );
                                } else {
                                  // Journey completed OR single challenge - show point breakdown
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChallengeCompletedPage(
                                        challengeId: widget.challengeId,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all<
                                        EdgeInsetsGeometry>(
                                    EdgeInsets.symmetric(
                                        horizontal:
                                            (MediaQuery.devicePixelRatioOf(
                                                        context) <
                                                    3
                                                ? 6
                                                : 10))),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        7.3), // Adjust the radius as needed
                                  ),
                                ),
                                side: MaterialStateProperty.all<BorderSide>(
                                  BorderSide(
                                    color: Color.fromARGB(255, 237, 86,
                                        86), // Specify the border color
                                    width: 2.0, // Specify the border width
                                  ),
                                ),
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                              ),
                              child: Text(
                                (isJourney && !journeyCompleted)
                                    ? 'Next Challenge'
                                    : 'Point Breakdown',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.devicePixelRatioOf(context) <
                                                3
                                            ? 12
                                            : 14,
                                    color: Color.fromARGB(255, 237, 86, 86)),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      // Confetti overlay for correct answers - constrained to dialog
                      if (isCorrect)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConfettiWidget(
                                confettiController: confettiController,
                                blastDirection: pi / 2, // Downward
                                maxBlastForce: 5,
                                minBlastForce: 2,
                                emissionFrequency: 0.05,
                                numberOfParticles: 5,
                                gravity: 0.1,
                                shouldLoop: false,
                                colors: const [
                                  Colors.green,
                                  Colors.blue,
                                  Colors.pink,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.yellow,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).then((_) {
      // Clean up confetti controller when dialog is dismissed
      confettiController.dispose();
    });
  }

  /// Show error dialog
  Future<void> _showErrorDialog(
      BuildContext context, QuizModel quizModel) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(quizModel.errorMessage ?? 'An error occurred'),
            actions: [
              TextButton(
                onPressed: () {
                  quizModel.clearError();
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
  }
}
