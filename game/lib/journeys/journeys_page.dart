import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/events/event_cell.dart';
import 'package:game/journeys/journey_cell.dart';
import 'package:game/journeys/filter_form.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class JourneysPage extends StatefulWidget {
  const JourneysPage({Key? key}) : super(key: key);

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  final cells = [
    JourneyCell(
      "DTI Scavenger Hunt",
      "Scavenger hunt during All Hands on 2/18",
      10,
      5,
      false,
      "normal",
      15,
      3,
    ),
    JourneyCell(
      "DTI Scavenger Hunt",
      "Scavenger hunt during All Hands on 2/18",
      10,
      0,
      false,
      "normal",
      15,
      3,
    ),
    JourneyCell(
      "Cornell Cafés",
      "Get your coffee fix at these top cafés on campus.",
      6,
      6,
      true,
      "normal",
      15,
      3,
    ),
    JourneyCell(
      "journey",
      "hi",
      0,
      0,
      false,
      "normal",
      15,
      3,
    ),
  ];

  void openFilter() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (
          BuildContext context,
        ) {
          return FilterForm();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
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
                      borderRadius: BorderRadius.all(Radius.circular(1.0))),
                  labelText: "Search a challenge name, location, etc...",
                  labelStyle: TextStyle(
                    color: Color.fromARGB(76, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 30,
                      child: TextButton.icon(
                          onPressed: openFilter,
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 20.0,
                          ),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
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
            ),
            // Expanded(
            //   child: ListView.separated(
            //     padding: const EdgeInsets.all(0),
            //     itemCount: cells.length,
            //     itemBuilder: (context, index) {
            //       return cells[index];
            //     },
            //     separatorBuilder: (context, index) {
            //       return SizedBox(height: 10);
            //     },
            //   ),
            // ),
            Expanded(child: Consumer5<EventModel, GroupModel, TrackerModel,
                    ChallengeModel, UserModel>(
                builder: (context, myEventModel, groupModel, trackerModel,
                    challengeModel, userModel, child) {
              List<Widget> eventCells = [];
              if (myEventModel.searchResults.length == 0) {
                myEventModel.searchEvents(
                    0,
                    1000,
                    [
                      EventRewardType.PERPETUAL,
                      EventRewardType.LIMITED_TIME_EVENT
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
                final tracker = trackerModel.trackerByEventId(event.id);
                final complete = tracker?.prevChallengeIds.length ==
                    event.challengeIds.length;
                final timeTillExpire = Duration(days: 2);
                // DateTime.parse(event.endTime).difference(DateTime.now());
                eventCells.add(
                  GestureDetector(
                    onTap: () {
                      if (groupModel.curEventId == event.id) return;
                      if (groupModel.members.any((element) =>
                          element.id == userModel.userData?.id &&
                          element.id == groupModel.group!.hostId)) {
                        // _showConfirmation(context, event.id, event.name);
                      } else {
                        showAlert("Ask the group leader to change the event.",
                            context);
                      }
                    },
                    child: StreamBuilder(
                      stream: Stream.fromFuture(Future.delayed(timeTillExpire)),
                      builder: (stream, value) => timeTillExpire.isNegative
                          ? Consumer<ApiClient>(
                              builder: (context, apiClient, child) {
                                if (event.id == groupModel.curEventId) {
                                  apiClient.serverApi?.setCurrentEvent("");
                                }
                                return Container();
                              },
                            )
                          //Backend is not formatted correctly for journeys
                          : JourneyCell(event.name, event.description, 4, 3,
                              complete, "Normal", event.minimumScore, 0),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(0),
                itemCount: eventCells.length,
                itemBuilder: (context, index) {
                  return eventCells[index];
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 10);
                },
              );
            }))
          ],
        ),
      ),
    );
  }
}
