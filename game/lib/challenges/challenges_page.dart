import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';
import 'challenge_cell_new.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
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
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.zero,
                    color: Color.fromARGB(76, 217, 217, 217),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        Icons.tune,
                        color: Color.fromARGB(204, 0, 0, 0),
                        size: 12,
                      ),
                      label: Text(
                        "filter",
                        style: TextStyle(
                          color: Color.fromARGB(204, 0, 0, 0),
                          fontSize: 12,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child:
                Consumer4<EventModel, GroupModel, TrackerModel, UserModel>(
                    builder: (context, myEventModel, groupModel, trackerModel,
                        userModel, child) {
              List<Widget> eventCells = [];
              if (myEventModel.searchResults!.length == 0) {
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
              final events = myEventModel.searchResults;
              if (!events!
                  .any((element) => element.id == groupModel.curEventId)) {
                final curEvent =
                    myEventModel.getEventById(groupModel.curEventId ?? "");
                if (curEvent != null) events.add(curEvent);
              }
              for (EventDto event in events) {
                var tracker = trackerModel.trackerByEventId(event.id);
                var complete = tracker?.prevChallengeIds.length ==
                    event.challengeIds.length;
                const timeTillExpire = Duration(days: 2);
                if (event.challengeIds.length > 1) continue;
                eventCells.add(
                  StreamBuilder(
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
                        : ChallengeCell(
                            "location",
                            event.name,
                            Image(image: AssetImage("assets/images/38582.jpg")),
                            complete,
                            event.description,
                            "normal",
                            event.minimumScore,
                            0),
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
