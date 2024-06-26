import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/achievements/achievements_page.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/achievement_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/achievements/achievement_cell.dart';
import 'package:game/profile/completed_cell.dart';
import 'package:game/profile/settings_page.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:game/profile/completed_feed.dart';
import 'package:velocity_x/velocity_x.dart';

/**
 * The profile page of the app that is rendered for the user's profile
 */
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 245, 234),
      body: SafeArea(child: Container(
        child: Consumer5<UserModel, EventModel, TrackerModel, ChallengeModel,
                AchievementModel>(
            builder: (context, userModel, eventModel, trackerModel,
                challengeModel, achModel, child) {
          if (userModel.userData == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final achList = achModel.getAvailableTrackerPairs();
          var username = userModel.userData?.username;
          var isGuest = userModel.userData?.authType == UserAuthTypeDto.device;
          var score = userModel.userData?.score;

          List<Tuple3<DateTime, EventDto, int>> completedEvents = [];

          //Get completed events
          for (var eventId in userModel.userData!.trackedEvents!) {
            if (completedEvents.length == 2) break;

            var tracker = trackerModel.trackerByEventId(eventId);
            EventDto? event = eventModel.getEventById(eventId);

            if (tracker == null || event == null) {
              continue;
            }
            if (tracker.prevChallenges.length != event.challenges!.length) {
              continue;
            }

            try {
              // prevChallenges.last will throw StateError if prevChallenges
              // is empty, meaning the challenge was not completed properly
              var completedDate = tracker.prevChallenges.last.dateCompleted;
              DateTime date =
                  DateFormat("E, d MMM y HH:mm:ss").parse(completedDate);
              int totalHintsUsed = 0;
              for (var prev in tracker.prevChallenges) {
                totalHintsUsed += prev.hintsUsed;
              }
              completedEvents.add(
                  Tuple3<DateTime, EventDto, int>(date, event, totalHintsUsed));
            } catch (e) {
              displayToast("Error with completing challenge", Status.error);
            }
          }
          //Sort so that the most recent events are first
          completedEvents.sort((a, b) => b.item1.compareTo(a.item1));
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
                                  builder: (context) => SettingsPage(isGuest)));
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
              //Completed Events
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CompletedFeedWidget()));
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
                height: MediaQuery.sizeOf(context).height * 0.25,
                width: MediaQuery.sizeOf(context).width * 0.85,
                child: ListView.separated(
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    if (index >= completedEvents.length) {
                      return Container();
                    }
                    var date = completedEvents[index].item1;
                    var event = completedEvents[index].item2;
                    var hintsUsed = completedEvents[index].item3;
                    String formattedDate = DateFormat("MMMM d, y").format(date);
                    var type =
                        event.challenges!.length > 1 ? "Journeys" : "Challenge";

                    // Calculate totalPoints.
                    var totalPoints = 0;
                    var locationImage;
                    for (var challengeId in event.challenges ?? []) {
                      var challenge =
                          challengeModel.getChallengeById(challengeId);
                      locationImage = challenge?.imageUrl;
                      if (locationImage == null || locationImage.length == 0)
                        locationImage =
                            "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png";
                      if (challenge != null) {
                        totalPoints += challenge.points ?? 0;
                      }
                    }

                    return completedCell(
                        context,
                        event.name!,
                        locationImage,
                        type,
                        formattedDate,
                        friendlyDifficulty[event.difficulty]!,
                        hintsUsed,
                        totalPoints);
                  },
                  physics: BouncingScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 10);
                  },
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
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AchievementsPage()));
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
              //To be replaced with real data
              Padding(
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: Column(
                      children: (achList
                          .sortedBy((a, b) => (a
                                      .$1.progress / // least completed first
                                  (a.$2.requiredPoints ?? 1))
                              .compareTo(
                                  b.$1.progress / (b.$2.requiredPoints ?? 1)))
                          .take(2)
                          .map((e) => ([
                                AchievementCell(
                                    e.$2.description ?? "",
                                    SvgPicture.asset(
                                        "assets/icons/achievementsilver.svg"),
                                    e.$1.progress,
                                    e.$2.requiredPoints ?? 0),
                                SizedBox(height: 10),
                              ]))
                          .expand((el) => el)
                          .toList()))),
            ],
          );
        }),
      )),
    );
  }
}
