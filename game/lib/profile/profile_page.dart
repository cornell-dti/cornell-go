import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/achievements/achievements_page.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/achievement_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/achievements/achievement_cell.dart';
import 'package:game/profile/completed_cell.dart';
import 'package:game/profile/build_a_bear/bear_preview.dart';
import 'package:game/profile/build_a_bear/build_a_bear_page.dart';
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
  /// Bear items loaded from the backend, filtered by slot.
  List<BearItemDto> _colorItems = [];
  List<BearItemDto> _eyeItems = [];
  List<BearItemDto> _mouthItems = [];
  List<BearItemDto> _accessoryItems = [];

  /// Currently equipped item IDs keyed by slot.
  Map<BearSlotDto, String?> _equippedBySlot = {};

  StreamSubscription<UpdateBearItemsDataDto>? _bearItemsSub;
  StreamSubscription<UpdateUserBearLoadoutDataDto>? _loadoutSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestBearData();
    });
  }

  @override
  void dispose() {
    _bearItemsSub?.cancel();
    _loadoutSub?.cancel();
    super.dispose();
  }

  void _requestBearData() {
    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) return;

    _bearItemsSub ??=
        apiClient.clientApi.updateBearItemsDataStream.listen((update) {
      setState(() {
        _colorItems = update.items
            .where((i) => i.slot == BearSlotDto.COLOR)
            .toList();
        _eyeItems = update.items
            .where((i) => i.slot == BearSlotDto.EYES)
            .toList();
        _mouthItems = update.items
            .where((i) => i.slot == BearSlotDto.MOUTH)
            .toList();
        _accessoryItems = update.items
            .where((i) => i.slot == BearSlotDto.ACCESSORY)
            .toList();
      });
    });

    _loadoutSub ??=
        apiClient.clientApi.updateUserBearLoadoutDataStream.listen((loadout) {
      setState(() {
        _equippedBySlot = {
          for (final e in loadout.equipped) e.slot: e.itemId,
        };
      });
    });

    server.requestBearItems(RequestBearItemsDto());
    server.requestUserBearLoadout(RequestUserBearLoadoutDto());
  }

  /// Look up the equipped [BearItemDto] for a given [slot].
  BearItemDto? _equippedItemForSlot(BearSlotDto slot) {
    final itemId = _equippedBySlot[slot];
    if (itemId == null) return null;
    final List<BearItemDto> items;
    switch (slot) {
      case BearSlotDto.COLOR:
        items = _colorItems;
        break;
      case BearSlotDto.EYES:
        items = _eyeItems;
        break;
      case BearSlotDto.MOUTH:
        items = _mouthItems;
        break;
      case BearSlotDto.ACCESSORY:
        items = _accessoryItems;
        break;
    }
    try {
      return items.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Calculate responsive sizes
    final headerHeight = screenHeight * 0.30;
    // Bear: size by header so it fits the green area; aspect 429w : 593h
    final bearHeight = headerHeight * 0.9;
    final bearWidth = bearHeight * (429 / 593);
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
            builder: (context, userModel, eventModel, trackerModel,
                challengeModel, achModel, child) {
          if (userModel.userData == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final achIds = userModel.getAvailableAchievementIds();
          final achList = achModel.getAvailableTrackerPairs(
            allowedAchievementIds: achIds,
          );
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

          // Sort achievements by progress (least completed first) and take top 2
          final sortedAchList = achList
              .sortedBy((a, b) => (a.$1.progress / // least completed first
                      (a.$2.requiredPoints ?? 1))
                  .compareTo(b.$1.progress / (b.$2.requiredPoints ?? 1)))
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
                      colors: [
                        Color(0xFF58B171),
                        Color(0xFF31B346),
                      ],
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
                      // Clothes hanger and settings icons positioned on the right
                      Positioned(
                        right: screenWidth * 0.05,
                        top: MediaQuery.of(context)
                            .padding
                            .top, // for status bar
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: SvgPicture.asset(
                                'assets/icons/clotheshanger.svg',
                                width: iconSize,
                                height: iconSize,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BuildABearPage(),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.settings,
                                  size: iconSize, color: Colors.black),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SettingsPage(isGuest)));
                              },
                            ),
                          ],
                        ),
                      ),
                      // Bear: anchored at bottom-center of header, sized to header
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom:
                            -headerHeight * 0.04, // Slight overlap with content
                        height: bearHeight,
                        child: Center(
                          child: BearPreview(
                            bearWidth: bearWidth,
                            bearHeight: bearHeight,
                            itemForSlot: _equippedItemForSlot,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile header section
                SizedBox(height: screenHeight * 0.018),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
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
                                    horizontal: 12, vertical: 2),
                                clipBehavior: Clip.antiAlias,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFC17E19),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 2,
                                      strokeAlign: BorderSide.strokeAlignCenter,
                                      color: const Color(0xFFFFC737),
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                SizedBox(height: screenHeight * 0.018), // 2.5% of screen height
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
                            fontSize: smallFontSize, // 3.5% of screen width
                          ),
                        ),
                      )
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
                        String formattedDate =
                            DateFormat("MMMM d, y").format(date);
                        var type = event.challenges!.length > 1
                            ? "Journeys"
                            : "Challenge";

                        // Calculate totalPoints.
                        var totalPoints = 0;
                        var locationImage;
                        for (var challengeId in event.challenges ?? []) {
                          var challenge =
                              challengeModel.getChallengeById(challengeId);
                          locationImage = challenge?.imageUrl;
                          if (locationImage == null ||
                              locationImage.length == 0)
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
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: 0),
                      separatorBuilder: (context, index) {
                        return SizedBox(
                            height:
                                screenHeight * 0.012); // 1.2% of screen height
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
                              fontSize: mediumFontSize, // 4% of screen width
                              fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          // Handle button press, e.g., navigate to details page
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AchievementsPage()));
                        },
                        child: Text(
                          'View All →',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: smallFontSize, // 3.5% of screen width
                          ),
                        ),
                      )
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
                      )))
                else
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            screenWidth * 0.075), // 7.5% of screen width
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
                                      : "assets/icons/achievementsilver.svg"),
                              e.$1.progress,
                              e.$2.requiredPoints ?? 0);
                        },
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 0),
                        separatorBuilder: (context, index) {
                          return SizedBox(
                              height: screenHeight *
                                  0.012); // 1.2% of screen height
                        },
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
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
