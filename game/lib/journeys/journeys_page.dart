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
import 'package:velocity_x/velocity_x.dart';

/** A Data Transfer Object that holds information about a challenge 
 * cell in the UI */
class JourneyCellDto {
  JourneyCellDto({
    required this.location,
    required this.name,
    required this.lat,
    required this.long,
    required this.imgUrl,
    required this.complete,
    required this.locationCount,
    required this.numberCompleted,
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
  late int locationCount;
  late int numberCompleted;
  late String description;
  late String difficulty;
  late int points;
  late String eventId;
}

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

/**
 * '_JourneysPageState' - Manages and displays a list of journeys, filtered by criteria such as difficulty, name, and more.
 * 
 * @remarks
 * This class handles the layout and logic for displaying journeys on the Journeys page. 
 * It builds `Journey` widgets and applies any filters set by the search bar
 * or user selections to show only the relevant journeys.
 */
class _JourneysPageState extends State<JourneysPage> {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedStatus = '';

  List<JourneyCellDto> eventData = [];

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
                  Expanded(child: Consumer6<UserModel, EventModel, GroupModel,
                          TrackerModel, ChallengeModel, ApiClient>(
                      builder: (context, userModel, myEventModel, groupModel,
                          trackerModel, challengeModel, apiClient, child) {
                    final allowedEventIds = userModel.getAvailableEventIds();

                    final events = allowedEventIds
                        .map((id) => myEventModel.getEventById(id))
                        .filter((element) => element != null)
                        .map((e) => e!)
                        .toList();
                    eventData.clear();

                    for (EventDto event in events) {
                      var tracker = trackerModel.trackerByEventId(event.id);
                      var numberCompleted = tracker?.prevChallenges.length ?? 0;
                      var complete =
                          (numberCompleted == event.challenges?.length);
                      var locationCount = event.challenges?.length ?? 0;

                      if (locationCount < 2) continue;
                      var totalPoints = 0;

                      var challenge = challengeModel
                          .getChallengeById(event.challenges?[0] ?? "");

                      if (challenge == null) continue;

                      for (var challengeId in event.challenges ?? []) {
                        var challenge =
                            challengeModel.getChallengeById(challengeId);
                        if (challenge != null) {
                          totalPoints += challenge.points ?? 0;
                        }
                      }
                      DateTime now = DateTime.now();
                      DateTime endtime = HttpDate.parse(event.endTime ?? "");

                      Duration timeTillExpire = endtime.difference(now);

                      final challengeLocation = challenge.location?.name ?? "";
                      final challengeName = challenge.name ?? "";
                      final String eventName = event.name ?? "";

                      bool eventMatchesDifficultySelection = true;
                      bool eventMatchesCategorySelection = true;
                      bool eventMatchesLocationSelection = true;
                      bool eventMatchesSearchText = true;
                      String searchTerm = widget.mySearchText ?? "";

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

                      if (searchTerm.length == 0) {
                        eventMatchesSearchText = true;
                      } else {
                        if (challengeLocation
                            .toLowerCase()
                            .contains(searchTerm.toLowerCase())) {
                          eventMatchesSearchText = true;
                        } else {
                          eventMatchesSearchText = false;
                          if (challengeName
                              .toLowerCase()
                              .contains(searchTerm.toLowerCase())) {
                            eventMatchesSearchText = true;
                          } else
                            eventMatchesSearchText = false;
                          if (eventName
                              .toLowerCase()
                              .contains(searchTerm.toLowerCase())) {
                            eventMatchesSearchText = true;
                          } else
                            eventMatchesSearchText = false;
                        }
                      }

                      var imageUrl = challenge.imageUrl;
                      if (imageUrl == null || imageUrl.length == 0) {
                        imageUrl =
                            "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png";
                      }

                      if (!complete &&
                          !timeTillExpire.isNegative &&
                          eventMatchesDifficultySelection &&
                          eventMatchesCategorySelection &&
                          eventMatchesLocationSelection &&
                          eventMatchesSearchText) {
                        eventData.add(JourneyCellDto(
                          location: friendlyLocation[challenge.location] ?? "",
                          name: event.name ?? "",
                          lat: challenge.latF ?? null,
                          long: challenge.longF ?? null,
                          imgUrl: imageUrl,
                          complete: complete,
                          locationCount: locationCount,
                          numberCompleted: numberCompleted,
                          description: event.description ?? "",
                          difficulty:
                              friendlyDifficulty[event.difficulty] ?? "",
                          points: totalPoints,
                          eventId: event.id,
                        ));
                      } else if (event.id == groupModel.curEventId) {
                        apiClient.serverApi
                            ?.setCurrentEvent(SetCurrentEventDto(eventId: ""));
                      }
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      itemCount: eventData.length,
                      itemBuilder: (context, index) {
                        return JourneyCell(
                            key: UniqueKey(),
                            eventData[index].name,
                            eventData[index].lat,
                            eventData[index].long,
                            eventData[index].location,
                            eventData[index].imgUrl,
                            eventData[index].description,
                            eventData[index].locationCount,
                            eventData[index].numberCompleted,
                            eventData[index].complete,
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
          // ],
        ),
        // ),
      ),
    ));
  }
}
