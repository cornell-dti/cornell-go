import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:game/gameplay/challenge_completed.dart';

class QuizProvider extends ChangeNotifier {
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

  final _rng = Random();
  int _curIdx = 0;
  List<String> _answers = [];
  int shuffleLeft = 3;
  int? selectedIdx;
  bool submitted = false;
  bool? correct;
  int totalPoints = 0;

  QuizProvider() {
    _answers = List<String>.from(_questionBank.first['answers']);
  }

  String get category => _questionBank[_curIdx]['category'];
  String get question => _questionBank[_curIdx]['question'];
  List<String> get answers => _answers;
  String get correctAnswer => _questionBank[_curIdx]['correct'];
  bool get isLast => _curIdx == _questionBank.length - 1;

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

  void selectAnswer(int i) {
    if (!submitted) {
      selectedIdx = i;
      notifyListeners();
    }
  }

  void submit() {
    if (selectedIdx == null || submitted) return;
    submitted = true;
    correct = _answers[selectedIdx!] == correctAnswer;
    if (correct == true) totalPoints += 10;
    notifyListeners();
  }

  void nextQuestion() {
    if (isLast) return;
    _curIdx++;
    _answers = List<String>.from(_questionBank[_curIdx]['answers']);
    shuffleLeft = 3;
    selectedIdx = null;
    submitted = false;
    correct = null;
    notifyListeners();
  }
}

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

class _QuizScreen extends StatelessWidget {
  const _QuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(builder: (context, quiz, _) {
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

  Widget _header(QuizProvider quiz) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12)),
        child: Text(quiz.category,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
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
                // header row
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

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (quiz.isLast) {
                        _showFinal(context, quiz.totalPoints);
                      } else {
                        quiz.nextQuestion();
                      }
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

  void _showFinal(BuildContext context, int pts) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text('Quiz Complete!'),
              content: Text(
                  'You earned $pts points.\nLeaderboard feature coming soon 🙂'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }
}
