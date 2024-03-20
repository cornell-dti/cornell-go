import 'package:flutter/material.dart';
import 'package:game/profile/profile_page.dart';
import 'package:game/profile/completed_challenge_cell.dart';

class CompletedChallengesPage extends StatelessWidget {
  final locationImage = "assets/images/adwhite.jpeg";
  final locationImage2 = "assets/images/38582.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 248, 241),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 237, 86, 86),
        leading: IconButton(
          icon: const Icon(Icons.navigate_before),
          color: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
        title: const Text(
          'Completed',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              child: completedChallengeFull(
                "Cornell Cafes",
                locationImage,
                "Journeys",
                "January 19, 2023",
                "Arts Quad",
                "Easy",
                120,
              ),
            ),
            Align(
              child: completedChallengeFull(
                "Cornell Slope",
                locationImage2,
                "Journeys",
                "March 20, 2024",
                "Libe Slope",
                "Easy",
                120,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
