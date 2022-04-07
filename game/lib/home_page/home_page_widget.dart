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
                showAlert(
                    "Congratulations! You've completed ${_doneState?.name}!",
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
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(gameModel.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
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
    return Consumer2<GameModel, GroupModel>(
        builder: (context, gameModel, groupModel, child) {
      var progressToUse = gameModel.withinCloseRadius
          ? gameModel.completionProgress
          : gameModel.closeProgress;
      var wrongPath = gameModel.directionDistance.abs() > 0.5;
      if (wrongPath) {
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
            child: Text(
              gameModel.description,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
              wrongPath
                  ? "You're going the wrong way"
                  : "You're on the right path",
              style: TextStyle(
                  color: wrongPath ? Colors.red : Colors.green,
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
                          colors: [
                            Colors.blue,
                            Colors.red,
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(32))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            gameModel.withinCloseRadius ? "Close" : "Far",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            gameModel.withinCloseRadius ? "Found" : "Close",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      ),
                    )),
                Container(
                    width: MediaQuery.of(context).size.width *
                        0.95 *
                        progressToUse,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomLeft: Radius.circular(32),
                        ))),
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
                onPressed: () => {print("Join-Group pressed")},
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
        ListView(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          children: getMembers(groupModel),
        )
      ]);
    });
  }

  List<Widget> getMembers(groupModel) {
    List<Widget> children = [];
    for (var member in groupModel.members) {
      children.add(_listCell(member.name, member.points.toString(), member.host,
          constructColorFromUserName(member.name)));
    }
    return children;
  }

  Widget _listCell(
    String name,
    String points,
    bool isUser,
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
                    Icon(Icons.check_box_rounded, color: Colors.grey),
                    Container(
                      alignment: Alignment.center,
                      child: isUser
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
                  child: ElevatedButton(
                    onPressed: () => {
                      showConfirmationAlert(
                          "You're about to leave this group. Please confirm.",
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
                  ));
            },
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }
}
