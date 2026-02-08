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
    final bearWidth = screenWidth * 0.35; // 35% of screen width
    final bearHeight =
        screenWidth * 0.35 * (593 / 429); // Maintain bear's aspect ratio
    final iconSize = screenWidth * 0.075; // 7.5% of screen width
    final badgeWidth = screenWidth * 0.2; // 20% of screen width
    final badgeHeight = screenHeight * 0.03; // 3% of screen height
    final smallFontSize = screenWidth * 0.035;
    final mediumFontSize = screenWidth * 0.04;

    // Responsive oval sizing
    final ovalWidth = screenWidth * 1; //full width of screen
    final ovalHeight = ovalWidth * (352 / 800); // Maintain aspect ratio

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 245, 234),
      body: Container(
        child: Consumer5<UserModel, EventModel, TrackerModel, ChallengeModel,
            AchievementModel>(
          builder: (
            context,
            userModel,
            eventModel,
            trackerModel,
            challengeModel,
            achModel,
            child,
          ) {
            if (userModel.userData == null) {
              return Center(child: CircularProgressIndicator());
            }

            final achIds = userModel.getAvailableAchievementIds();
            final achList = achModel.getAvailableTrackerPairs(
              allowedAchievementIds: achIds,
            );
            var username = userModel.userData?.username;
            var isGuest =
                userModel.userData?.authType == UserAuthTypeDto.device;
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
                DateTime date = DateFormat(
                  "E, d MMM y HH:mm:ss",
                ).parse(completedDate);
                int totalHintsUsed = 0;
                for (var prev in tracker.prevChallenges) {
                  totalHintsUsed += prev.hintsUsed;
                }
                completedEvents.add(
                  Tuple3<DateTime, EventDto, int>(date, event, totalHintsUsed),
                );
              } catch (e) {
                displayToast("Error with completing challenge", Status.error);
              }
            }
            //Sort so that the most recent events are first
            completedEvents.sort((a, b) => b.item1.compareTo(a.item1));

            // Sort achievements by progress (least completed first) and take top 2
            final sortedAchList = achList
                .sortedBy(
                  (a, b) => (a.$1.progress / // least completed first
                          (a.$2.requiredPoints ?? 1))
                      .compareTo(
                    b.$1.progress / (b.$2.requiredPoints ?? 1),
                  ),
                )
                .take(2)
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Green gradient background with blue oval
                  Container(
                    width: double.infinity,
                    height: headerHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF58B171), Color(0xFF31B346)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -headerHeight *
                              0.7, // Position to cut off more at top
                          left: -ovalWidth /
                              2, // Center the oval, the left edge starts halfway to left of screen
                          child: Container(
                            width: ovalWidth * 2,
                            height: ovalHeight * 2,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFB3EBF6),
                              shape: OvalBorder(),
                            ),
                          ),
                        ),
                        // Sun icon in top left corner
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 45,
                          child: Container(
                            width: iconSize,
                            height: iconSize,
                            child: Image.asset(
                              'assets/icons/sun.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Cloud icon positioned on layer above sun to partially cover it
                        Positioned(
                          top: MediaQuery.of(context).padding.top - 17,
                          left: 30,
                          child: Container(
                            width: iconSize * 3,
                            height: iconSize * 3,
                            child: Image.asset(
                              'assets/icons/cloud.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Settings icon positioned on the right
                        Positioned(
                          right: screenWidth *
                              0.05, // will shift this to the right when hanger icon is introduced
                          top: MediaQuery.of(
                            context,
                          ).padding.top, // for status bar
                          child: IconButton(
                            icon: Icon(
                              Icons.settings,
                              size: iconSize,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(isGuest),
                                ),
                              );
                            },
                          ),
                        ),
                        // Centered bear.png image
                        Center(
                          child: Container(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top - 10,
                            ),
                            child: Container(
                              width: bearWidth,
                              height: bearHeight,
                              child: Image.asset(
                                'assets/icons/bear.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile header section
                  SizedBox(height: screenHeight * 0.018),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Container(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  username!,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.055,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    height: 1.50,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFC17E19),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 2,
                                        strokeAlign:
                                            BorderSide.strokeAlignCenter,
                                        color: const Color(0xFFFFC737),
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${score} PTS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: smallFontSize,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              '@${username.toLowerCase().replaceAll(' ', '')}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: mediumFontSize,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.018,
                  ), // 2.5% of screen height
                  //Completed Events
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                    ), // 6% of screen width
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Completed",
                          style: TextStyle(
                            fontSize: mediumFontSize, // 4% of screen width
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompletedFeedWidget(),
                              ),
                            );
                          },
                          child: Text(
                            'View All →',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: smallFontSize, // 3.5% of screen width
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (completedEvents.isEmpty)
                    SizedBox(
                      height: screenHeight * 0.21,
                      width: screenWidth * 0.85,
                      child: Center(
                        child: Text(
                          "No Completed Events",
                          style: TextStyle(
                            fontSize: mediumFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: screenWidth * 0.85, // 85% of screen width
                      child: ListView.separated(
                        shrinkWrap:
                            true, // this prevents the list from being scrollable
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          if (index >= completedEvents.length) {
                            return Container();
                          }
                          var date = completedEvents[index].item1;
                          var event = completedEvents[index].item2;
                          var hintsUsed = completedEvents[index].item3;
                          String formattedDate = DateFormat(
                            "MMMM d, y",
                          ).format(date);
                          var type = event.challenges!.length > 1
                              ? "Journeys"
                              : "Challenge";

                          // Calculate both adjusted and original total points
                          var totalAdjustedPoints = 0;
                          var totalOriginalPoints = 0;
                          var locationImage;
                          // Get tracker for this event to access prevChallenges
                          var eventTracker =
                              trackerModel.trackerByEventId(event.id);
                          if (eventTracker != null) {
                            for (var prevChallenge
                                in eventTracker.prevChallenges) {
                              var challenge = challengeModel
                                  .getChallengeById(prevChallenge.challengeId);
                              if (locationImage == null) {
                                locationImage = challenge?.imageUrl;
                                if (locationImage == null ||
                                    locationImage.length == 0)
                                  locationImage =
                                      "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png";
                              }
                              if (challenge != null) {
                                // Calculate adjusted points: first apply extension deduction, then hint adjustment
                                int basePoints = challenge.points ?? 0;
                                totalOriginalPoints +=
                                    basePoints; // Sum original points

                                // If challenge was failed (timer expired), award 0 points
                                if (prevChallenge.failed == true) {
                                  // Failed challenges earn 0 points
                                  totalAdjustedPoints += 0;
                                } else {
                                  int extensionsUsed = 0;
                                  try {
                                    extensionsUsed =
                                        prevChallenge.extensionsUsed ?? 0;
                                  } catch (e) {
                                    // Field not initialized, use default of 0
                                    extensionsUsed = 0;
                                  }
                                  int extensionAdjustedPoints =
                                      calculateExtensionAdjustedPoints(
                                          basePoints, extensionsUsed);
                                  int finalAdjustedPoints =
                                      calculateHintAdjustedPoints(
                                          extensionAdjustedPoints,
                                          prevChallenge.hintsUsed);
                                  totalAdjustedPoints += finalAdjustedPoints;
                                }
                              }
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
                            totalAdjustedPoints,
                            totalOriginalPoints,
                          );
                        },
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 0),
                        separatorBuilder: (context, index) {
                          return SizedBox(
                            height: screenHeight * 0.012,
                          ); // 1.2% of screen height
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                    ), // 6% of screen width
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Achievements",
                          style: TextStyle(
                            fontSize: mediumFontSize, // 4% of screen width
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle button press, e.g., navigate to details page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AchievementsPage(),
                              ),
                            );
                          },
                          child: Text(
                            'View All →',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: smallFontSize, // 3.5% of screen width
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //To be replaced with real data
                  if (achList.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.1),
                      child: Center(
                        child: Text(
                          "No Available Achievements",
                          style: TextStyle(
                            fontSize: mediumFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.075,
                      ), // 7.5% of screen width
                      child: SizedBox(
                        width: screenWidth * 0.85, // 85% of screen width
                        child: ListView.separated(
                          shrinkWrap:
                              true, // this prevents the list from being scrollable
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            if (index >= sortedAchList.length) {
                              return Container();
                            }
                            final e = sortedAchList[index];
                            return AchievementCell(
                              e.$2.description ?? "",
                              SvgPicture.asset(
                                e.$1.progress >= (e.$2.requiredPoints ?? 0)
                                    ? "assets/icons/achievementgold.svg"
                                    : "assets/icons/achievementsilver.svg",
                              ),
                              e.$1.progress,
                              e.$2.requiredPoints ?? 0,
                            );
                          },
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(top: 0),
                          separatorBuilder: (context, index) {
                            return SizedBox(
                              height: screenHeight * 0.012,
                            ); // 1.2% of screen height
                          },
                        ),
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            );
          },
        ),
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
      0,
      size.height - size.height * 0.1,
    ); // 10% of height from bottom

    // Create a very subtle curve (like the bottom of an oval)
    path.quadraticBezierTo(
      size.width / 2, // Control point x at center
      size.height +
          size.height *
              0.08, // Control point y below bottom edge by 8% of height
      size.width, // End point x at right edge
      size.height - size.height * 0.1, // End point y same as start height
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
