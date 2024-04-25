import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/achievements/achievement_cell.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/achievement_model.dart';
import 'package:game/model/user_model.dart';
import 'package:provider/provider.dart';

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

  List<AchievementCellDto> eventData = [];

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
                        Expanded(child: Consumer5<EventModel, GroupModel,
                                TrackerModel, ChallengeModel, ApiClient>(
                            builder: (context,
                                myEventModel,
                                groupModel,
                                trackerModel,
                                challengeModel,
                                apiClient,
                                child) {
                          if (myEventModel.searchResults == null) {
                            myEventModel.searchEvents(
                                0,
                                1000,
                                [
                                  EventTimeLimitationDto.PERPETUAL,
                                  EventTimeLimitationDto.LIMITED_TIME
                                ],
                                false,
                                false,
                                false);
                          }
                          final events = myEventModel.searchResults ?? [];
                          if (!events.any((element) =>
                              element.id == groupModel.curEventId)) {
                            final curEvent = myEventModel
                                .getEventById(groupModel.curEventId ?? "");
                            if (curEvent != null) events.add(curEvent);
                          }
                          eventData.clear();

                          for (EventDto event in events) {
                            var tracker =
                                trackerModel.trackerByEventId(event.id);
                            var numberCompleted =
                                tracker?.prevChallenges.length ?? 0;
                            var complete =
                                (numberCompleted == event.challenges?.length);
                            var locationCount = event.challenges?.length ?? 0;
                            DateTime now = DateTime.now();
                            DateTime endtime =
                                HttpDate.parse(event.endTime ?? "");

                            Duration timeTillExpire = endtime.difference(now);
                            if (locationCount != 1) continue;
                            var challenge = challengeModel
                                .getChallengeById(event.challenges?[0] ?? "");

                            // print("Doing Event with now/endtime " + event.description.toString() + now.toString() + "/" + endtime.toString());
                            if (challenge == null) {
                              // print("Challenge is null for event " + event.description.toString());

                              continue;
                            }
                            final challengeLocation =
                                challenge.location?.name ?? "";

                            bool eventMatchesDifficultySelection;
                            bool eventMatchesCategorySelection;
                            bool eventMatchesLocationSelection;

                            if (selectedDifficulty.length == 0 ||
                                selectedDifficulty == event.difficulty?.name)
                              eventMatchesDifficultySelection = true;
                            else
                              eventMatchesDifficultySelection = false;

                            if (selectedLocations.length > 0) {
                              if (selectedLocations.contains(challengeLocation))
                                eventMatchesLocationSelection = true;
                              else
                                eventMatchesLocationSelection = false;
                            } else
                              eventMatchesLocationSelection = true;

                            if (selectedCategories.length > 0) {
                              if (selectedCategories
                                  .contains(event.category?.name))
                                eventMatchesCategorySelection = true;
                              else
                                eventMatchesCategorySelection = false;
                            } else
                              eventMatchesCategorySelection = true;
                            if (!complete &&
                                !timeTillExpire.isNegative &&
                                eventMatchesDifficultySelection &&
                                eventMatchesCategorySelection &&
                                eventMatchesLocationSelection) {
                              eventData.add(AchievementCellDto(
                                location:
                                    friendlyLocation[challenge.location] ?? "",
                                name: event.name ?? "",
                                lat: challenge.latF ?? null,
                                long: challenge.longF ?? null,
                                thumbnail: SvgPicture.asset(
                                    "assets/icons/achievementsilver.svg"),
                                complete: complete,
                                description: event.description ?? "",
                                difficulty:
                                    friendlyDifficulty[event.difficulty] ?? "",
                                points: challenge.points ?? 0,
                                eventId: event.id,
                              ));
                            } else if (event.id == groupModel.curEventId) {
                              apiClient.serverApi?.setCurrentEvent(
                                  SetCurrentEventDto(eventId: ""));
                            }
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            itemCount: eventData.length,
                            itemBuilder: (context, index) {
                              return AchievementCell(
                                  key: UniqueKey(),
                                  eventData[index].location,
                                  eventData[index].name,
                                  eventData[index].lat,
                                  eventData[index].long,
                                  eventData[index].thumbnail,
                                  eventData[index].complete,
                                  eventData[index].description,
                                  eventData[index].difficulty,
                                  eventData[index].points,
                                  eventData[index].eventId);
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
