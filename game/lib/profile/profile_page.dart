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
 * `ProfilePage` Component - Displays the user's profile information and achievements.
 * 
 * @remarks
 * This component serves as the main profile screen in the CornellGO app, presenting
 * the user's personal information, completed events, and achievements. It features
 * a custom curved header with the user's avatar and score, followed by sections for
 * completed events and achievements.
 * 
 * The layout is responsive, with dimensions calculated as percentages of screen size
 * to ensure consistent appearance across different devices. It consumes data from
 * multiple providers including UserModel, EventModel, TrackerModel, ChallengeModel,
 * and AchievementModel.
 * 
 * @param key - Optional Flutter widget key for identification and testing.
 * 
 * @returns A StatefulWidget that displays the user profile interface.
 */

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Calculate responsive sizes
    final headerHeight = screenHeight * 0.30;
    final avatarSize = screenWidth * 0.22; // 22% of screen width
    final iconSize = screenWidth * 0.075; // 7.5% of screen width
    final badgeWidth = screenWidth * 0.2; // 20% of screen width
    final badgeHeight = screenHeight * 0.03; // 3% of screen height
    final smallFontSize = screenWidth * 0.035;
    final mediumFontSize = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 245, 234),
      body: Container(
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
              // Red curved header with profile information
              Stack(
                children: [
                  // Custom curved container
                  ClipPath(
                    clipper: CustomCurveClipper(),
                    child: Container(
                      width: double.infinity,
                      height: headerHeight,
                      color:
                          Color(0xFFED5656), // Coral red color from the design
                    ),
                  ),
                  // Content inside the curved container
                  Column(
                    children: [
                      // Add padding for status bar
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      // Profile section with settings icon
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05),
                        child: Stack(
                          children: [
                            // Settings icon positioned on the right
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.settings,
                                    size: iconSize, color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SettingsPage(isGuest)));
                                },
                              ),
                            ),
                            // Centered profile content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Profile avatar
                                  Container(
                                    height: screenHeight * 0.14,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Avatar
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: SvgPicture.asset(
                                            "assets/images/bear_profile.svg",
                                            height: avatarSize,
                                            width: avatarSize,
                                          ),
                                        ),
                                        // Points badge
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: badgeWidth,
                                            height: badgeHeight,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: ShapeDecoration(
                                              color: Color(0xFFC17E19),
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  width: 2,
                                                  strokeAlign: BorderSide
                                                      .strokeAlignCenter,
                                                  color: Color(0xFFFFC737),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${score} PTS",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * fontSize,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Add space between avatar/points and username
                                  SizedBox(height: screenHeight * 0.015),
                                  // Username
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        username!,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.055,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: screenHeight * 0.002),
                                      Text(
                                        "@${username.toLowerCase().replaceAll(' ', '')}",
                                        style: TextStyle(
                                          fontSize: mediumFontSize,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025), // 2.5% of screen height
              //Completed Events
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06), // 6% of screen width
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Completed",
                        style: TextStyle(
                            fontSize: mediumFontSize, // 4% of screen width
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CompletedFeedWidget()));
                      },
                      child: Text(
                        'View All →',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize:
                              screenWidth * fontSize, // 3.5% of screen width
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: screenHeight * 0.25, // 25% of screen height
                width: screenWidth * 0.85, // 85% of screen width
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
                    return SizedBox(
                        height: screenHeight * 0.012); // 1.2% of screen height
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06), // 6% of screen width
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Achievements",
                        style: TextStyle(
                             0.fontSize: screenWidth *04, // 4% of screen width
                            fontWeight: FontWeight.bold)),
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
                          fontSize:
                              screenWidth * fontSize, // 3.5% of screen width
                        ),
                      ),
                    )
                  ],
                ),
              ),
              //To be replaced with real data
              Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.075), // 7.5% of screen width
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
                                SizedBox(
                                    height: screenHeight *
                                        0.012), // 1.2% of screen height
                              ]))
                          .expand((el) => el)
                          .toList()))),
            ],
          );
        }),
      ),
    );
  }
}

/**
 * `CustomCurveClipper` - Creates a custom curved shape for the profile header.
 * 
 * @remarks
 * This clipper generates a path with a subtle curve at the bottom edge of the
 * profile header, creating a visually appealing transition between the header
 * and the content below. The curve is designed to be gentle, resembling the
 * bottom of an oval, with the lowest point at the center of the width.
 * 
 * @param size - The size of the area to be clipped, containing width and height.
 * 
 * @returns A Path object defining the custom curved shape for clipping.
 * 
 * @shouldReclip - Returns false as the clip shape doesn't change dynamically.
 */

class CustomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.lineTo(
        0, size.height - size.height * 0.1); // 10% of height from bottom

    // Create a very subtle curve (like the bottom of an oval)
    path.quadraticBezierTo(
        size.width / 2, // Control point x at center
        size.height +
            size.height *
                0.08, // Control point y below bottom edge by 8% of height
        size.width, // End point x at right edge
        size.height - size.height * 0.1 // End point y same as start height
        );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
