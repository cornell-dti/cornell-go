import 'package:flutter/material.dart';
import 'package:game/profile/achievement_cell.dart';
import 'package:game/profile/completed_cell.dart';
import 'package:game/settings/settings.dart';

/**
 * The profile page of the app that is rendered for the user's profile
 */
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final locationImage = "assets/images/38582.jpg";
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Color.fromARGB(255, 255, 245, 234),
          body: Container(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 20),
                    child: IconButton(
                        alignment: Alignment.topRight,
                        icon: Icon(Icons.settings, size: 40),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsWidget()));
                        }),
                  ),
                ),
                Container(
                  height: 120,
                  child: Stack(
                    children: [
                      Center(
                        child: Image(
                          image: AssetImage("assets/images/user_2@2x.png"),
                        ),
                      ),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 30,
                            width: 100,
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 246, 228, 201),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Center(
                              child: Text(
                                '246 points',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    "Hanan Abraha",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("@Hanan Abraha"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                      ),
                      child: Text("Achievements",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle button press, e.g., navigate to details page
                        print('View Details button pressed');
                      },
                      child: Text(
                        'View Details →',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    )
                  ],
                ),
                achievementCell("Complete three challenges on the Arts quad", 4,
                    6, locationImage),
                achievementCell(
                    "Complete three challenges on the Engineering quad",
                    4,
                    6,
                    locationImage),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text("Completed",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle button press, e.g., navigate to details page
                        print('View Details button pressed');
                      },
                      child: Text(
                        'View More →',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    )
                  ],
                ),
                completedCell("Cornell Cafes", locationImage, "Journeys",
                    "January 19, 2023", "Arts Quad", "Easy", 120),
                completedCell("Cornell Cafes", locationImage, "Journeys",
                    "January 19, 2023", "Arts Quad", "Easy", 120),
              ],
            ),
          )),
    );
  }
}
