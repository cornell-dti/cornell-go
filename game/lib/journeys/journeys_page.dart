import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/journeys/journey_cell.dart';
import 'package:game/journeys/filter_form.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';

class JourneysPage extends StatefulWidget {
  const JourneysPage({Key? key}) : super(key: key);

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
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
            Expanded(child:
                Consumer4<EventModel, GroupModel, TrackerModel, UserModel>(
                    builder: (context, myEventModel, groupModel, trackerModel,
                        userModel, child) {
              List<Widget> eventCells = [];
              if (myEventModel.searchResults == null) {
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
                var tracker = trackerModel.trackerByEventId(event.id);
                var numberCompleted = tracker?.prevChallengeIds.length ?? 0;
                var complete = (numberCompleted == event.challengeIds.length);
                var locationCount = event.challengeIds.length;
                var difficulty = event.difficulty;
                const timeTillExpire = Duration(days: 2);
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
                          : JourneyCell(
                              event.name,
                              event.description,
                              locationCount,
                              numberCompleted,
                              complete,
                              difficulty,
                              event.minimumScore,
                              0),
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
