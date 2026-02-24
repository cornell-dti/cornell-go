import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/achievements/achievement_cell.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/achievement_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/model/tracker_model.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:game/constants/constants.dart';

class AchievementCellDto {
  AchievementCellDto({
    required this.location,
    required this.name,
    required this.lat,
    required this.long,
    required this.thumbnail,
    required this.complete,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.eventId,
  });
  late String location;
  late String name;
  late double? lat;
  late double? long;
  late SvgPicture thumbnail;
  late bool complete;
  late String description;
  late String difficulty;
  late int points;
  late String eventId;
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

/**
 * The achievements page of the app that displays a list of trackable user achievements.
 * `_AchievementsPageState` Class - A page where users can view their progress toward completing various achievements within the app.
 *
 * @remarks
 * This component serves as the screen where users can browse their available achievements in the app. It provides a clean, scrollable interface for users to track:
 * - Achievement descriptions
 * - Current progress toward each achievement
 * - Total required points to complete each achievement
 *
 * The component utilizes a custom `AchievementCell` widget to display individual achievements. It retrieves the list of achievements from the `AchievementModel` using the `getAvailableTrackerPairs()` method and dynamically populates the UI.
 *
 * The page layout is responsive and styled with consistent design patterns used throughout the app. It also provides safe navigation through a back button in the app bar.
 *
 * The component listens to real-time updates from both the `AchievementModel` and `ApiClient` using `Consumer2` from the `provider` package, ensuring the list of achievements stays current without requiring a manual refresh.
 *
 * @param key - Optional Flutter widget key for identification and testing (used within `AchievementCell`).
 *
 * @returns A StatefulWidget that displays a scrollable list of the user's achievements with their progress.
 */
class _AchievementsPageState extends State<AchievementsPage> {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedDifficulty = '';
  @override
  Widget build(BuildContext context) {
    var headerStyle = TextStyle(
      color: AppColors.warmWhite,
      fontSize: 20,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    );

    return Container(
      decoration: BoxDecoration(color: AppColors.primaryRed),
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryRed,
            toolbarHeight: MediaQuery.of(context).size.height * 0.08,
            leading: Align(
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(Icons.navigate_before),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.01,
              ),
              child: Text('Achievements', style: headerStyle),
            ),
            centerTitle: true,
            actions: [],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
            ),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Expanded(
                    child: Consumer4<AchievementModel, ApiClient, UserModel,
                        GroupModel>(
                      builder: (
                        context,
                        achModel,
                        apiClient,
                        userModel,
                        groupModel,
                        child,
                      ) {
                        final achIds = userModel.getAvailableAchievementIds();
                        final achList = achModel.getAvailableTrackerPairs(
                          allowedAchievementIds: achIds,
                        );

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                          ),
                          itemCount: achList.length,
                          itemBuilder: (context, index) {
                            // Check if the achievement is completed
                            bool completed = achList[index].$1.progress >=
                                (achList[index].$2.requiredPoints ?? 0);
                            return AchievementCell(
                              key: UniqueKey(),
                              achList[index].$2.description ?? "",
                              SvgPicture.asset(
                                completed
                                    ? "assets/icons/achievementgold.svg"
                                    : "assets/icons/achievementsilver.svg",
                              ),
                              achList[index].$1.progress,
                              achList[index].$2.requiredPoints ?? 0,
                            );
                          },
                          physics: BouncingScrollPhysics(),
                          separatorBuilder: (context, index) {
                            return SizedBox(height: 10);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
