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
import 'package:game/utils/utility_functions.dart';
import 'package:game/model/tracker_model.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

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

class _AchievementsPageState extends State<AchievementsPage> {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedDifficulty = '';

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Color(0xFFED5656),
        ),
        child: SafeArea(
            bottom: false,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Achievements'),
              ),
              body: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 248, 241),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Expanded(child: Consumer2<AchievementModel, ApiClient>(
                            builder: (context, achModel, apiClient, child) {
                          final achTrackers = achModel.getAchievementTrackers();

                          final achList = achTrackers
                              .map((e) => (
                                    e,
                                    achModel.getAchievementById(e.achievementId)
                                  ))
                              .filter((e) => e.$2 != null)
                              .map((e) => (e.$1, e.$2!))
                              .toList();

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            itemCount: achList.length,
                            itemBuilder: (context, index) {
                              return AchievementCell(
                                  key: UniqueKey(),
                                  achList[index].$2.description ?? "",
                                  SvgPicture.asset(
                                      "assets/icons/achievementsilver.svg"),
                                  achList[index].$1.progress,
                                  achList[index].$2.requiredPoints ?? 0);
                            },
                            physics: BouncingScrollPhysics(),
                            separatorBuilder: (context, index) {
                              return SizedBox(height: 10);
                            },
                          );
                        }))
                      ],
                    ),
                  )),
            )));
  }
}
