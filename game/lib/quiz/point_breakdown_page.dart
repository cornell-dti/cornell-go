import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PointBreakdownPage extends StatelessWidget {
  final String locationTitle;
  final int challenge1Points;
  final int challenge2Points;
  final int quizPoints;
  final int totalPoints;
  final int answeredQuestions;
  final int totalQuestions;
  final VoidCallback onReturnHome;

  const PointBreakdownPage({
    super.key,
    this.locationTitle = 'the Statue on the Arts Quad',
    required this.challenge1Points,
    required this.challenge2Points,
    required this.quizPoints,
    required this.totalPoints,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalQuestions == 0
        ? 0.0
        : (answeredQuestions / totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/challenge-completed-bg.svg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              allowDrawingOutsideViewBox: true,
              placeholderBuilder: (_) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8FD7FF), Color(0xFF2BA94D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          // Foreground content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'Journey Complete',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You’ve found $locationTitle!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Progress bar + label (pin + 3/3)
                  _ProgressBar(
                    value: ratio,
                    labelIcon: 'assets/icons/pin.svg',
                    labelText: '$answeredQuestions/$totalQuestions',
                  ),

                  const SizedBox(height: 22),

                  // Card with points
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF), // translucent white
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),

                        _PointRow(
                          iconAsset: 'assets/icons/locationCompleted.svg',
                          label: 'Challenge 1',
                          value: challenge1Points,
                        ),
                        _PointRow(
                          iconAsset: 'assets/icons/locationCompleted.svg',
                          label: 'Challenge 2',
                          value: challenge2Points,
                        ),
                        _PointRow(
                          iconAsset: 'assets/icons/locationCompleted.svg',
                          label: 'Quiz',
                          value: quizPoints,
                          prefix: '+',
                        ),

                        const SizedBox(height: 16),
                        const Divider(
                          color: Colors.white70,
                          thickness: 1,
                          height: 24,
                        ),
                        const SizedBox(height: 6),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Points: ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.95),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              '$totalPoints',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFED5656),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Return Home',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final String labelIcon;
  final String labelText;

  const _ProgressBar({
    required this.value,
    required this.labelIcon,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bar
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0x30FFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A8A), Color(0xFFED5656)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Pin + label
        Row(
          children: [
            SvgPicture.asset(
              labelIcon,
              width: 18,
              height: 18,
              color: Colors.white,
              placeholderBuilder: (_) =>
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 6),
            Text(
              labelText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PointRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final int value;
  final String prefix;

  const _PointRow({
    required this.iconAsset,
    required this.label,
    required this.value,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Small rounded square icon badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6D7FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1B9FF)),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              color: const Color(0xFF7A43D1),
              placeholderBuilder: (_) => const Icon(
                Icons.flag,
                color: Color(0xFF7A43D1),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            '$prefix$value',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
