import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/geopoint.dart'; //same package as preview.dart
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
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
    this.distanceFromChallenge, // not required for challenge cell to be displayed
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
  late double? distanceFromChallenge; // Distance from user's current location (null if not calculable)
}

class ChallengesPage extends StatefulWidget {
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  String? mySearchText;

  ChallengesPage(
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
  State<ChallengesPage> createState() => _ChallengesPageState(
      myDifficulty, myLocations, myCategories, mySearchText);
}

class _ChallengesPageState extends State<ChallengesPage> {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedDifficulty = '';
  String? mySearchText;
  List<ChallengeCellDto> eventData = [];
  GeoPoint? currentUserLocation;

  _ChallengesPageState(String? difficulty, List<String>? locations,
      List<String>? categories, String? searchText) {
    selectedDifficulty = difficulty ?? '';
    selectedLocations = locations ?? [];
    selectedCategories = categories ?? [];
    mySearchText = searchText ?? '';
  }

// initialize widget state as normal + load user location
  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  /// Loads the user's current location for distance calculations
  void _loadUserLocation() async {
    try {
      // Get fresh location (GeoPoint.current() will get the most up-to-date location)
      GeoPoint location = await GeoPoint.current();
      if (mounted) { // only set state if widget is still mounted
        setState(() {
          currentUserLocation = location;
        });
      }
    } catch (e) {
      print("Error loading user location: $e");
      // Continue without location - challenges will show unsorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 248, 241),
        ),
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

                        bool eventMatchesDifficultySelection = true;
                        bool eventMatchesCategorySelection = true;
                        bool eventMatchesLocationSelection = true;
                        bool eventMatchesSearchText = true;
                        String? searchTerm = widget.mySearchText;

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

                        if (searchTerm?.length == 0) {
                          eventMatchesSearchText = true;
                        } else {
                          // search term length > 0
                          if (searchTerm != null &&
                              challengeLocation
                                  .toLowerCase()
                                  .contains(searchTerm.toLowerCase())) {
                            eventMatchesSearchText = true;
                          } else {
                            eventMatchesSearchText = false;
                            if (searchTerm != null &&
                                (event.name ?? "")
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
                          // distance calculations
                          double? distance;
                          if (currentUserLocation != null &&
                              challenge.latF != null &&
                              challenge.longF != null) {
                            try {
                              GeoPoint challengeLocation = GeoPoint(
                                  challenge.latF!, challenge.longF!, 0);
                              distance = currentUserLocation!
                                  .distanceTo(challengeLocation);
                            } catch (e) {
                              print("Error calculating distance: $e"); // not fatal but it will log the error
                            }
                          }

                          eventData.add(ChallengeCellDto(
                            location:
                                friendlyLocation[challenge.location] ?? "",
                            name: event.name ?? "",
                            lat: challenge.latF ?? null,
                            long: challenge.longF ?? null,
                            imgUrl: imageUrl,
                            complete: complete,
                            description: event.description ?? "",
                            difficulty:
                                friendlyDifficulty[event.difficulty] ?? "",
                            points: challenge.points ?? 0,
                            eventId: event.id,
                            distanceFromChallenge: distance,
                          ));
                        } else if (event.id == groupModel.curEventId) {
                          apiClient.serverApi?.setCurrentEvent(
                              SetCurrentEventDto(eventId: ""));
                        }
                      }

                      // Sort by distance (null distances go to the end)
                      eventData.sort((a, b) {
                        if (a.distanceFromChallenge == null &&
                            b.distanceFromChallenge == null) {
                          return 0; // Both null, keep original order
                        }
                        if (a.distanceFromChallenge == null) return 1; // a goes to end
                        if (b.distanceFromChallenge == null) return -1; // b goes to end of list
                        return a.distanceFromChallenge!
                            .compareTo(b.distanceFromChallenge!); // Sort ascending
                      });

                      // eventCells.forEach((Widget anEventCell) {
                      //   print("AnEventCell is " + anEventCell.toString());
                      // });

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
                              eventData[index].eventId,
                              eventData[index].distanceFromChallenge);
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
            )),
      ),
    );
  }
}
