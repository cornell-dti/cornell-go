import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'point_breakdown_page.dart';

/// Provider that manages the quiz state, including question tracking,
/// answer selection, point calculation, and shuffle logic.
class QuizProvider extends ChangeNotifier {
  // List of all quiz questions and associated metadata.
  final List<Map<String, dynamic>> _questionBank = [
    {
      'category': 'Physical',
      'question': 'What is the item the statue is holding in his right hand?',
      'answers': ['Book', 'Torch', 'Sword', 'Pen'],
      'correct': 'Torch',
    },
    {
      'category': 'History',
      'question': 'What was one of Andrew Dickson White’s key contributions?',
      'answers': [
        'Created Cornell’s medical school.',
        'Co‑founded the university.',
        'Designed first graduate programs.',
        'Funded the library.'
      ],
      'correct': 'Co‑founded the university.',
    },
    {
      'category': 'History',
      'question': 'Which animal is Cornell’s unofficial mascot?',
      'answers': ['Bear', 'Big Red', 'Dragon', 'Panther'],
      'correct': 'Big Red',
    },
  ];

  final _rng = Random(); // For shuffling questions
  int _curIdx = 0; // Index of current question
  List<String> _answers = []; // Shuffled answer list
  int shuffleLeft = 3; // Shuffle attempts remaining
  int? selectedIdx; // Index of selected answer
  bool submitted = false; // Whether the user has submitted the answer
  bool? correct; // Whether the submitted answer is correct
  int totalPoints = 0; // Cumulative points

  QuizProvider() {
    _answers = List<String>.from(_questionBank.first['answers']);
  }

  // Getters to expose relevant quiz data
  String get category => _questionBank[_curIdx]['category'];
  String get question => _questionBank[_curIdx]['question'];
  List<String> get answers => _answers;
  String get correctAnswer => _questionBank[_curIdx]['correct'];

  /// Shuffle to a new question (if remaining shuffles exist and answer not yet submitted)
  void shuffle() {
    if (shuffleLeft == 0 || submitted) return;
    int newIdx = _curIdx;
    while (newIdx == _curIdx) {
      newIdx = _rng.nextInt(_questionBank.length);
    }
    _curIdx = newIdx;
    _answers = List<String>.from(_questionBank[_curIdx]['answers']);
    _answers.shuffle();
    selectedIdx = null;
    shuffleLeft--;
    notifyListeners();
  }

  /// Record user's selected answer index
  void selectAnswer(int i) {
    if (!submitted) {
      selectedIdx = i;
      notifyListeners();
    }
  }

  /// Submit the selected answer, update points if correct
  void submit() {
    if (selectedIdx == null || submitted) return;
    submitted = true;
    correct = _answers[selectedIdx!] == correctAnswer;
    if (correct == true) totalPoints += 10;
    notifyListeners();
  }
}

/// Entry widget for quiz page that initializes the provider
class QuizPage extends StatelessWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(),
      child: const _QuizScreen(),
    );
  }
}

/// Main quiz UI screen
class _QuizScreen extends StatelessWidget {
  const _QuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(builder: (context, quiz, _) {
      // Show result dialog immediately after submission
      if (quiz.submitted) {
        Future.microtask(() => _showResultDialog(context, quiz));
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF9F5F1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE95755),
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: const Text('Quiz', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _header(quiz),
            const SizedBox(height: 16),
            _questionCard(quiz),
            const SizedBox(height: 16),
            _answerList(quiz),
            const Spacer(),
            _submitBtn(quiz),
          ]),
        ),
      );
    });
  }

  /// Category + Points header bar
  Widget _header(QuizProvider quiz) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      // Quiz category label
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12)),
        child: Text(quiz.category,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      // Points display
      Row(children: [
        SvgPicture.asset('assets/icons/bearcoins.svg',
            height: 18, width: 18, color: const Color(0xFFC17E19)),
        const SizedBox(width: 4),
        Text('${quiz.totalPoints} PTS',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC17E19))),
      ]),
    ]);
  }

  /// Displays the current question and a shuffle button
  Widget _questionCard(QuizProvider quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(quiz.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: quiz.shuffle,
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE95755)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Text('Shuffle (${quiz.shuffleLeft})',
              style: const TextStyle(
                  color: Color(0xFFE95755), fontWeight: FontWeight.w600)),
        )
      ]),
    );
  }

  /// Generates tappable list of answer options
  Widget _answerList(QuizProvider quiz) {
    return Column(
      children: List.generate(quiz.answers.length, (idx) {
        final active = quiz.selectedIdx == idx;
        return GestureDetector(
          onTap: () => quiz.selectAnswer(idx),
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
              child: Text(quiz.answers[idx],
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: active ? const Color(0xFFE95755) : Colors.black)),
            ),
          ),
        );
      }),
    );
  }

  /// Submit button to finalize the answer
  Widget _submitBtn(QuizProvider quiz) {
    final enabled = quiz.selectedIdx != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? quiz.submit : null,
        style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFFE95755).withOpacity(enabled ? 1 : 0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        child: const Text('Submit',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  /// Modal that shows up after answer submission
  Future<void> _showResultDialog(
      BuildContext context, QuizProvider quiz) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    await showDialog(
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        context: context,
        builder: (_) {
          final isCorrect = quiz.correct ?? false;
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Dialog header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isCorrect ? 'Correct!' : 'Sorry…',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCorrect
                                ? const Color(0xFF58B171)
                                : const Color(0xFFE95755))),
                    InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 18))
                  ],
                ),
                const SizedBox(height: 12),

                // Body depending on correctness
                if (isCorrect) ...[
                  SvgPicture.asset('assets/icons/confetti.svg',
                      height: 80, width: 80),
                  const SizedBox(height: 16),
                  const Text(
                    "Yay! You've earned points to move up the leaderboard.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SvgPicture.asset('assets/icons/bearcoins.svg',
                        height: 18, width: 18),
                    const SizedBox(width: 4),
                    const Text('+10 PTS',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                ] else ...[
                  RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14),
                          children: [
                            const TextSpan(text: 'The correct answer was '),
                            TextSpan(
                                text: quiz.correctAnswer,
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
                      Navigator.pop(context);
                      _showFinal(context, quiz.totalPoints);
                    },
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE95755))),
                    child: Text('Results',
                        style: const TextStyle(
                            color: Color(0xFFE95755), fontSize: 14)),
                  ),
                ),
              ]),
            ),
          );
        });
  }

  /// Final summary dialog shown after the last quiz question
  void _showFinal(BuildContext context, int pts) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PointBreakdownPage(
          challenge1Points: 100,
          challenge2Points: 100,
          quizPoints: pts,
          totalPoints: 100 + 100 + pts,
          answeredQuestions: 3,
          totalQuestions: 3,
          onReturnHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
