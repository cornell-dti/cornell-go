import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/journeys/journey_cell.dart';
import 'package:game/journeys/filter_form.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';

class JourneysPage extends StatefulWidget {
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  String? mySearchText;
  // const JourneysPage({Key? key}) : super(key: key);

  JourneysPage(
      {Key? key,
      String? difficulty,
      List<String>? locations,
      List<String>? categories,
      String? searchText})
      : super(key: key) {
    myDifficulty = difficulty;
    myLocations = locations;
    myCategories = categories;
    mySearchText = searchText;
  }

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedStatus = 'Easy';

  void openFilter() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (
          BuildContext context,
        ) {
          return FilterForm(onSubmit: handleFilterSubmit);
        });
  }

  // Callback function to receive updated state values from the child
  void handleFilterSubmit(List<String> a, List<String> b, String c) {
    setState(() {
      selectedCategories = a;
      selectedLocations = b;
      selectedStatus = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 248, 241), // Background color
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(child: Consumer4<EventModel, GroupModel, TrackerModel,
                        ChallengeModel>(
                    builder: (context, myEventModel, groupModel, trackerModel,
                        challengeModel, child) {
                  List<Widget> eventCells = [];
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
                  if (!events
                      .any((element) => element.id == groupModel.curEventId)) {
                    final curEvent =
                        myEventModel.getEventById(groupModel.curEventId ?? "");
                    if (curEvent != null) events.add(curEvent);
                  }
                  for (EventDto event in events) {
                    var tracker = trackerModel.trackerByEventId(event.id);
                    var numberCompleted = tracker?.prevChallenges?.length ?? 0;
                    var complete =
                        (numberCompleted == event.challenges?.length);
                    var locationCount = event.challenges?.length ?? 0;

                    if (locationCount < 2) continue;
                    var totalPoints = 0;

                    var challenge = challengeModel
                        .getChallengeById(event.challenges?[0] ?? "");

                    if (challenge == null) continue;
                    var location = challenge.location;

                    for (var challengeId in event.challenges ?? []) {
                      var challenge =
                          challengeModel.getChallengeById(challengeId);
                      if (challenge != null) {
                        totalPoints += challenge.points ?? 0;
                      }
                    }
                    var difficulty = event.difficulty;
                    DateTime now = DateTime.now();
                    DateTime endtime = HttpDate.parse(event.endTime ?? "");

                    Duration timeTillExpire = endtime.difference(now);

                    final challengeLocation = challenge.location?.name ?? "";
                    final challengeName = challenge.name ?? "";

                    bool eventMatchesDifficultySelection = true;
                    bool eventMatchesCategorySelection = true;
                    bool eventMatchesLocationSelection = true;
                    bool eventMatchesSearchText = true;
                    String? searchTerm = widget.mySearchText;

                    if (searchTerm?.length == 0) {
                      eventMatchesSearchText = true;
                      if (widget.myDifficulty?.length == 0 ||
                          widget.myDifficulty == event.difficulty?.name)
                        eventMatchesDifficultySelection = true;
                      else
                        eventMatchesDifficultySelection = false;

                      if (widget.myLocations?.isNotEmpty ?? false) {
                        if (widget.myLocations?.contains(challengeLocation) ??
                            false)
                          eventMatchesLocationSelection = true;
                        else
                          eventMatchesLocationSelection = false;
                      } else
                        eventMatchesLocationSelection = true;

                      if (widget.myCategories?.isNotEmpty ?? false) {
                        if (widget.myCategories
                                ?.contains(event.category?.name) ??
                            false)
                          eventMatchesCategorySelection = true;
                        else
                          eventMatchesCategorySelection = false;
                      } else
                        eventMatchesCategorySelection = true;
                    } else {
                      if (challengeLocation != null &&
                          searchTerm != null &&
                          challengeLocation
                              .toLowerCase()
                              .contains(searchTerm.toLowerCase())) {
                        eventMatchesSearchText = true;
                      } else {
                        eventMatchesSearchText = false;
                        if (challengeName != null &&
                            searchTerm != null &&
                            challengeName
                                .toLowerCase()
                                .contains(searchTerm.toLowerCase())) {
                          eventMatchesSearchText = true;
                        } else
                          eventMatchesSearchText = false;
                      }
                    }

                    if (!complete)
                      eventCells.add(
                        StreamBuilder(
                          stream:
                              Stream.fromFuture(Future.delayed(timeTillExpire)),
                          builder: (stream, value) => timeTillExpire
                                      .isNegative ||
                                  (eventMatchesDifficultySelection == false ||
                                      eventMatchesCategorySelection == false ||
                                      eventMatchesLocationSelection == false) ||
                                  eventMatchesSearchText == false
                              ? Consumer<ApiClient>(
                                  builder: (context, apiClient, child) {
                                    if (event.id == groupModel.curEventId) {
                                      apiClient.serverApi?.setCurrentEvent(
                                          SetCurrentEventDto(eventId: ""));
                                    }
                                    return Container();
                                  },
                                )
                              : JourneyCell(
                                  key: UniqueKey(),
                                  event.name ?? "",
                                  friendlyLocation[location] ?? "",
                                  Image.network(
                                      "https://picsum.photos/250?image=9"), // dummy data for now; should pass in thumbnail parameter
                                  event.description ?? "",
                                  locationCount,
                                  numberCompleted,
                                  complete,
                                  friendlyDifficulty[difficulty] ?? "",
                                  totalPoints, event.id,
                                ),
                        ),
                      );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    itemCount: eventCells.length + 1,
                    itemBuilder: (context, index) {
                      if (index == eventCells.length) {
                        // Footer widget
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 50.0),
                            child: Center(
                              child: Image(
                                image: AssetImage('assets/images/go-logo.png'),
                                width: 200,
                                height: 200,
                              ),
                            ));
                      }
                      return eventCells[index];
                    },
                    physics: BouncingScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 10);
                    },
                  );
                }))
              ],
            ),
          ),
          // ],
        ),
        // ),
      ),
    );
  }
}
