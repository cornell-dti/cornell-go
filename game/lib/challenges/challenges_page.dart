import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'challenge_cell.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  /* Dummy code, to be replaced */
  final cells = [
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        false,
        "Find this famous statue!",
        "Easy",
        15,
        3),
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        true,
        "Find this famous statue!",
        "Normal",
        15,
        3),
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        false,
        "Find this famous statue!",
        "Hard",
        15,
        3),
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        true,
        "Find this famous statue!",
        "Challenging",
        15,
        3),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        builder: (context, myEventModel, groupModel,
                            trackerModel, userModel, child) {
                  List<Widget> eventCells = [];
                  if (myEventModel.searchResults == null) {
                    myEventModel.searchEvents(
                        0,
                        1000,
                        [
                          TimeLimitationType.PERPETUAL,
                          TimeLimitationType.LIMITED_TIME
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
                    var complete =
                        (numberCompleted == event.challengeIds.length);
                    var locationCount = event.challengeIds.length;
                    var difficulty = event.difficulty;
                    DateTime now = DateTime.now();
                    DateTime endtime = HttpDate.parse(event.endTime);

                    Duration timeTillExpire = endtime.difference(now);
                    eventCells.add(
                      StreamBuilder(
                        stream:
                            Stream.fromFuture(Future.delayed(timeTillExpire)),
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
                                key: UniqueKey(),
                                event.name,
                                Image.network(
                                    "https://picsum.photos/250?image=9"), // dummy data for now; should pass in thumbnail parameter
                                event.description,
                                locationCount,
                                numberCompleted,
                                complete,
                                difficulty,
                                event.minimumScore,
                                0),
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
          )),
    );
  }
}
