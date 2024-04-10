import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/profile/achievement_cell.dart';
import 'package:game/profile/completed_cell.dart';
import 'package:game/profile/settings_page.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 245, 234),
      body: SafeArea(child: Container(
        child: Consumer2<EventModel, UserModel>(
            builder: (context, eventModel, userModel, child) {
          if (userModel.userData == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          var username = userModel.userData?.username;
          var score = userModel.userData?.score;
          print(userModel.userData?.toJson());
          var completedChallengesId = userModel.userData?.completedChallenges;
          var completedChallenges = [];

          if (completedChallengesId != null) {
            completedChallenges = completedChallengesId
                .map((e) => eventModel.getEventById(e))
                .toList();
          }
          return Column(
            children: [
              Stack(fit: StackFit.passthrough, children: [
                Center(
                  child: Container(
                    height: 160,
                    padding: EdgeInsets.only(top: 30),
                    child: Stack(
                      children: [
                        Center(
                          child: SvgPicture.asset("assets/images/bear_prof.svg",
                              height: 100, width: 100),
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
                                score.toString() + " points",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: TextDirection.rtl,
                  start: 10,
                  // top: 22,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 20),
                    child: IconButton(
                        alignment: Alignment.topRight,
                        icon: Icon(Icons.settings, size: 40),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsPage()));
                        }),
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  username!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Achievements",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        // Handle button press, e.g., navigate to details page
                        print('View Details button pressed');
                      },
                      child: Text(
                        'View Details →',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              achievementCell("Complete three challenges on the Arts quad", 4,
                  6, locationImage),
              achievementCell(
                  "Complete three challenges on the Engineering quad",
                  4,
                  6,
                  locationImage),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Completed",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        // Handle button press, e.g., navigate to details page
                        print('View Details button pressed');
                      },
                      child: Text(
                        'View More →',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    if (index >= completedChallenges.length) {
                      return Container();
                    }
                    var event = completedChallenges[index];
                    var type =
                        event.challenges.length > 1 ? "Journeys" : "Challenge";
                    return completedCell(
                        event.name,
                        locationImage,
                        type,
                        event.date,
                        event.location,
                        event.difficulty,
                        event.score);
                  },
                  physics: BouncingScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 10);
                  },
                ),
              ),
            ],
          );
        }),
      )),
    );
  }
}
