import 'package:flutter/material.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:game/widget/nav_bar.dart';
import 'package:game/widget/nav_btn.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/model/game_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/user_model.dart';
import 'package:confetti/confetti.dart';

class HomePageWidget extends StatefulWidget {
  HomePageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late ConfettiController _controllerCenter =
      ConfettiController(duration: Duration(seconds: 10));
  TextEditingController textController = TextEditingController();
  TextEditingController idController = new TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Color Carnelian = Color(0xFFB31B1B);
  var _doneState = null;
  @override
  void initState() {
    super.initState();
    ;
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = const BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    return Scaffold(
        floatingActionButton: navBtn(scaffoldKey, context),
        drawer: NavBar(),
        key: scaffoldKey,
        backgroundColor: const Color(0xFFFFFF),
        body: Consumer5<ApiClient, GameModel, GroupModel, UserModel,
            TrackerModel>(
          builder: (context, apiClient, gameModel, groupModel, userModel,
              trackerModel, child) {
            WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
              if (gameModel.withinCompletionRadius) {
                final tracker =
                    trackerModel.trackerByEventId(groupModel.curEventId ?? "")!;

                if (tracker.prevChallengeIds.contains(tracker.curChallengeId))
                  return;

                tracker.prevChallengeIds.add(tracker.curChallengeId);
                setState(() {
                  _doneState = gameModel;
                });
              }
              if (_doneState != null && gameModel.hasConnection) {
                _controllerCenter.play();
                apiClient.serverApi?.completedChallenge(_doneState.challengeId);
                showAlert("Congratulations! You've found ${_doneState?.name}!",
                    context);
                setState(() {
                  _doneState = null;
                });
              }
            });
            return Stack(children: [
              Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: _controllerCenter,
                  blastDirectionality: BlastDirectionality
                      .explosive, // don't specify a direction, blast randomly
                  shouldLoop: true,
                ),
              ),
              Container(
                child: FadeInImage(
                  image: NetworkImage(gameModel.imageUrl == ""
                      ? "https://images.freeimages.com/images/large-previews/bdb/free-blurry-background-1636594.jpg"
                      : gameModel.imageUrl),
                  fit: BoxFit.cover,
                  placeholder: AssetImage("assets/images/black.png"),
                  placeholderFit: BoxFit.cover,
                ),
                height: 1000,
              ),
              SlidingUpPanel(
                  minHeight: 200,
                  padding: const EdgeInsets.all(8),
                  backdropEnabled: true,
                  backdropTapClosesPanel: true,
                  borderRadius: radius,
                  parallaxEnabled: true,
                  color: Colors.black87,
                  header: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 3.5,
                    alignment: Alignment.center,
                    child: Container(
                        width: 70,
                        height: 3.5,
                        decoration: new BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        )),
                  ),
                  panel: _panel()),
            ]);
          },
        ));
  }

  Widget _panel() {
    return Consumer4<GameModel, GroupModel, UserModel, TrackerModel>(builder:
        (context, gameModel, groupModel, userModel, trackerModel, child) {
      final progressToUse = gameModel.withinCloseRadius
          ? gameModel.completionProgress
          : gameModel.closeProgress;
      final isDoneWithoutConnection =
          _doneState != null && !gameModel.hasConnection;
      if (gameModel.directionDistance < 0) {
        displayToast("You're going the wrong way!", Status.error);
      }
      return VStack([
        Row(
          children: [
            Padding(
                padding: EdgeInsets.all(6),
                child: HStack([
                  Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.follow_the_signs_rounded,
                          color: Carnelian)),
                  Padding(
                    padding: EdgeInsets.all(3),
                    child: Text(gameModel.walkingTime,
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ])),
            if (!gameModel.hasConnection)
              Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.signal_wifi_off, color: Carnelian)),
            Padding(
                padding: EdgeInsets.all(6),
                child: HStack([
                  Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.group_add_rounded,
                          color: Color(0xFFB31B1B))),
                  Padding(
                    padding: EdgeInsets.all(3),
                    child: Text(
                        groupModel.members.length.toString() + " members",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ]))
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
        Container(
          margin: new EdgeInsets.symmetric(vertical: 0),
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(height: 48),
              child: Text(
                gameModel.description,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
              gameModel.directionDistance.abs() < 2
                  ? "Start moving!"
                  : gameModel.directionDistance < 0
                      ? "You're going the wrong way"
                      : "You're on the right path",
              style: TextStyle(
                  color: gameModel.directionDistance < 2
                      ? Colors.orange
                      : gameModel.directionDistance < 0
                          ? Colors.red
                          : Colors.green,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          margin: new EdgeInsets.symmetric(vertical: 20),
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.center,
          child: VStack([
            Stack(
              children: [
                Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: 40,
                    decoration: new BoxDecoration(
                        color: Colors.white,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.topRight,
                          colors: isDoneWithoutConnection
                              ? [Colors.green, Colors.green]
                              : [
                                  Colors.blue,
                                  Colors.red,
                                ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(32))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: isDoneWithoutConnection
                            ? [
                                Text(
                                  "Find an internet connection to finish...",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                )
                              ]
                            : [
                                Text(
                                  gameModel.withinCloseRadius ? "Close" : "Far",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  gameModel.withinCloseRadius
                                      ? "Found"
                                      : "Close",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                )
                              ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      ),
                    )),
                Container(
                  width: isDoneWithoutConnection
                      ? 0
                      : MediaQuery.of(context).size.width *
                          (1 - (0.85 * progressToUse + 0.15)),
                  height: 40,
                  margin: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width *
                          (0.85 * progressToUse + 0.1)),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(32))),
                ),
              ],
            )
          ]),
        ),
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              Consumer<UserModel>(builder: ((context, value, child) {
                return Text(
                  "Group [" +
                      (value.userData?.groupId.toUpperCase() ?? "") +
                      "]",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                );
              })),
              ElevatedButton(
                onPressed: () => {_joinGroupDialog(context)},
                child: const Text(
                  "Join!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                    backgroundColor: Carnelian,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)))),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.grey),
                  bottom: BorderSide(color: Colors.grey),
                  left: BorderSide(color: Colors.grey),
                  right: BorderSide(color: Colors.grey))),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: getMembers(userModel, groupModel, trackerModel),
            ),
          ),
        )
      ]);
    });
  }

  List<Widget> getMembers(
      UserModel userModel, GroupModel groupModel, TrackerModel trackerModel) {
    List<Widget> children = [];
    for (var member in groupModel.members) {
      children.add(_listCell(
          member.name,
          member.points.toString(),
          member.id == userModel.userData?.id && groupModel.members.length > 1,
          member.host,
          member.curChallengeId ==
              trackerModel
                  .trackerByEventId(groupModel.curEventId ?? '')
                  ?.curChallengeId,
          constructColorFromUserName(member.name)));
    }
    return children;
  }

  Widget _listCell(
    String name,
    String points,
    bool isUser,
    bool isHost,
    bool isSameChallenge,
    Color userColor,
  ) {
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 5,
                child: Row(
                  children: [
                    Icon(
                        isSameChallenge
                            ? Icons.search
                            : Icons.check_box_rounded,
                        color: Colors.grey),
                    Container(
                      alignment: Alignment.center,
                      child: isHost
                          ? Text(
                              "👑",
                              style: TextStyle(fontSize: 20),
                            )
                          : null,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: userColor,
                          borderRadius: BorderRadius.circular(15)),
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: Carnelian, fontWeight: FontWeight.bold)),
                  Text(
                    points,
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  )
                ],
              )
            ],
          ),
          Consumer2<ApiClient, UserModel>(
            builder: (context, apiClient, userModel, child) {
              return Container(
                  width: MediaQuery.of(context).size.width / 4,
                  child: isUser
                      ? Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: ElevatedButton(
                            onPressed: () => {
                              showLeaveConfirmationAlert(
                                  "Are you sure you want to leave this group?",
                                  context,
                                  apiClient)
                            },
                            child: Text(
                              "Leave",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: TextButton.styleFrom(
                                backgroundColor: Carnelian,
                                shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)))),
                          ),
                        )
                      : Container(height: 48));
            },
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Future<void> _joinGroupDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Join Group'),
            content: TextField(
              controller: idController,
              decoration: InputDecoration(hintText: "Group ID"),
            ),
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
                    child: Text('JOIN'),
                    onPressed: () {
                      apiClient.serverApi
                          ?.joinGroup(idController.text.toLowerCase());
                      Navigator.pop(context);
                    },
                  );
                },
              )
            ],
          );
        });
  }

  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }
}
