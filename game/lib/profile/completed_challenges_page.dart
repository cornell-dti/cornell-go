import 'package:flutter/material.dart';
import 'package:game/profile/profile_page.dart';
import 'package:game/profile/completed_challenge_cell.dart';

/* The page view of all the completed challenges */

class CompletedChallengesPage extends StatelessWidget {
  // final locationImage = "assets/images/adwhite.jpeg";
  // final locationImage2 = "assets/images/38582.jpg";

  final pictureList = ["assets/images/adwhite.jpeg", "assets/images/38582.jpg"];

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
              child: CompletedChallengeFull(
                name: 'Cornell Cafes',
                pictures: pictureList,
                type: 'Journeys',
                date: 'January 19, 2023',
                location: 'Arts Quad',
                difficulty: 'Easy',
                points: 120,
              ),
            ),
            Align(
              child: CompletedChallengeFull(
                name: 'Libe Slope',
                pictures: [
                  "assets/images/adwhite.jpeg",
                  "assets/images/38582.jpg",
                ],
                type: 'Journeys',
                date: 'February 20, 2023',
                location: 'Arts Quad',
                difficulty: 'Hard',
                points: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
