import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'challenge_cell.dart';
import 'package:game/journeys/filter_form.dart';

class ChallengeCellDto {
  ChallengeCellDto({
    required this.location,
    required this.name,
    required this.lat,
    required this.long,
    required this.imgUrl,
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
  late String imgUrl;
  late bool complete;
  late String description;
  late String difficulty;
  late int points;
  late String eventId;
}

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedDifficulty = '';

  List<ChallengeCellDto> eventData = [];

  // Callback function to receive updated state values from the child
  void handleFilterSubmit(List<String>? a, List<String>? b, String c) {
    setState(() {
      selectedCategories = a ?? [];
      selectedLocations = b ?? [];
      selectedDifficulty = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 248, 241),
          ),
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image(
                    image: AssetImage('assets/images/go-logo.png'),
                    width: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.height / 3,
                  ),
                ),
                Column(
                  children: [
                    Container(
                      height: 30,
                      color: Color.fromARGB(51, 217, 217, 217),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color.fromARGB(204, 0, 0, 0),
                            size: 12,
                          ),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(1.0))),
                          labelText:
                              "Search a challenge name, location, etc...",
                          labelStyle: TextStyle(
                            color: Color.fromARGB(76, 0, 0, 0),
                            fontSize: 12,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 30,
                            child: TextButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => FilterForm(
                                        onSubmit: handleFilterSubmit,
                                        difficulty: selectedDifficulty,
                                        locations: selectedLocations,
                                        categories: selectedCategories),
                                  );
                                },
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  size: 20.0,
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Color.fromARGB(153, 217, 217, 217)),
                                  padding: MaterialStateProperty.all(
                                    EdgeInsets.only(right: 16.0, left: 16.0),
                                  ),
                                  shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3.0),
                                  )),
                                ),
                                label: Text(
                                  "Filter By",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                  ),
                                )),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Consumer5<EventModel, GroupModel,
                            TrackerModel, ChallengeModel, ApiClient>(
                        builder: (context, myEventModel, groupModel,
                            trackerModel, challengeModel, apiClient, child) {
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
                      if (!events.any(
                          (element) => element.id == groupModel.curEventId)) {
                        final curEvent = myEventModel
                            .getEventById(groupModel.curEventId ?? "");
                        if (curEvent != null) events.add(curEvent);
                      }
                      eventData.clear();

                      for (EventDto event in events) {
                        var tracker = trackerModel.trackerByEventId(event.id);
                        var numberCompleted =
                            tracker?.prevChallenges.length ?? 0;
                        var complete =
                            (numberCompleted == event.challenges?.length);
                        var locationCount = event.challenges?.length ?? 0;
                        DateTime now = DateTime.now();
                        DateTime endtime = HttpDate.parse(event.endTime ?? "");

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
                          if (selectedCategories.contains(event.category?.name))
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
                          eventData.add(ChallengeCellDto(
                            location:
                                friendlyLocation[challenge.location] ?? "",
                            name: event.name ?? "",
                            lat: challenge.latF ?? null,
                            long: challenge.longF ?? null,
                            imgUrl: challenge.imageUrl ??
                                "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png",
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
                          return ChallengeCell(
                              key: UniqueKey(),
                              eventData[index].location,
                              eventData[index].name,
                              eventData[index].lat,
                              eventData[index].long,
                              eventData[index].imgUrl,
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
              ],
            ),
          )),
    );
  }
}
