import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
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

Future<void> _showConfirmation(
    BuildContext context, String eventId, String eventName) async {
  await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Switch to Event'),
          content: Text('Are you sure you want to switch to $eventName?'),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Consumer<ApiClient>(
              builder: (context, apiClient, child) {
                return TextButton(
                  child: Text('YES'),
                  onPressed: () {
                    apiClient.serverApi?.setCurrentEvent(eventId);
                    Navigator.pop(context);
                  },
                );
              },
            )
          ],
        );
      });
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
                    final chal = event.challengeIds.length == 0
                        ? null
                        : challengeModel
                            .getChallengeById(event.challengeIds[0]);
                    final complete = tracker?.prevChallengeIds.length ==
                        event.challengeIds.length;
                    eventCells.add(GestureDetector(
                      onTap: () {
                        _showConfirmation(context, event.id, event.name);
                      },
                      child: eventsCell(
                          context,
                          event.name,
                          event.time == null || !complete
                              ? ""
                              : format.format(event.time!),
                          event.description,
                          complete,
                          event.id == groupModel.curEventId,
                          (event.rewardType ==
                                  UpdateEventDataEventRewardTypeDto.PERPETUAL
                              ? null
                              : event.time),
                          reward ?? "",
                          event.rewards.length,
                          event.requiredMembers,
                          chal?.imageUrl ??
                              "https://a.rgbimg.com/users/b/ba/badk/600/qfOGvbS.jpg"),
                    ));
                  }
                  return ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      children: eventCells);
                }))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
