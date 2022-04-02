import 'package:flutter/material.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/widget/back_btn.dart';
import 'package:game/widget/events_cell.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventsWidget extends StatefulWidget {
  EventsWidget({Key? key}) : super(key: key);

  @override
  _EventsWidgetState createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: backBtn(scaffoldKey, context, "Events"),
      backgroundColor: Color.fromARGB(255, 43, 47, 50),
      body: Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
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
                          UpdateEventDataEventRewardTypeDto.PERPETUAL,
                          UpdateEventDataEventRewardTypeDto.LIMITED_TIME_EVENT
                        ],
                        false,
                        false,
                        false);
                  }
                  for (UpdateEventDataEventDto event
                      in myEventModel.searchResults ?? []) {
                    final reward = event.rewards.length == 0
                        ? null
                        : event.rewards[0].description;
                    final tracker = trackerModel.trackerByEventId(event.id);
                    final format = DateFormat('yyyy-MM-dd');
                    final date = event.time
                        ?.difference(DateTime.now())
                        .toString()
                        .split(".")[0];
                    final chal =
                        challengeModel.getChallengeById(event.challengeIds[0]);
                    eventCells.add(eventsCell(
                        context,
                        event.name,
                        event.time == null ? "" : format.format(event.time!),
                        event.description,
                        tracker?.prevChallengeIds.length ==
                            event.challengeIds.length,
                        event.id == groupModel.curEventId,
                        date ?? "",
                        reward ?? "",
                        event.rewards.length,
                        event.requiredMembers,
                        chal?.imageUrl ??
                            "https://a.rgbimg.com/users/b/ba/badk/600/qfOGvbS.jpg"));
                  }
                  return ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      children: eventCells);
                }))
                // Expanded(
                //     child: ListView(
                //         shrinkWrap: true,
                //         scrollDirection: Axis.vertical,
                //         children: [
                //       eventsCell(
                //           context,
                //           "Central Campus Event",
                //           "4/19/2021",
                //           "Learn more about this commonly visited area through the central campus event",
                //           true,
                //           false,
                //           -1,
                //           "Completion certificate",
                //           -1,
                //           -1,
                //           "assets/images/38582.jpg"),
                //       eventsCell(
                //           context,
                //           "Central Campus Event",
                //           "4/19/2021",
                //           "Learn more about this commonly visited area through the central campus event",
                //           false,
                //           true,
                //           3,
                //           "3\$ Cornell Store",
                //           3,
                //           -1,
                //           "assets/images/38582.jpg"),
                //       eventsCell(
                //           context,
                //           "Central Campus Event",
                //           "4/19/2021",
                //           "Learn more about this commonly visited area through the central campus event",
                //           false,
                //           false,
                //           -1,
                //           "",
                //           0,
                //           3,
                //           "assets/images/38582.jpg"),
                //     ]))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
