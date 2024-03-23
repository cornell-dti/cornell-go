import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/global_leaderboard/podium_widgets.dart';
import 'package:game/widget/leaderboard_cell.dart';
import 'package:game/widget/podium_cell.dart';
import 'package:provider/provider.dart';

/**
 * This widget defines the leaderboard page. 
 */
class GlobalLeaderboardWidget extends StatefulWidget {
  const GlobalLeaderboardWidget({Key? key}) : super(key: key);

  @override
  _GlobalLeaderboardWidgetState createState() =>
      _GlobalLeaderboardWidgetState();
}

/**
 * This widget is the mutable state of the global leaderboard. Currently, if the system has less than 3 users
 * then empty users with no name are added to the podium. 
 */
class _GlobalLeaderboardWidgetState extends State<GlobalLeaderboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    var leaderboardStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'Lato',
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      height: 29.0 / 24.0,
      letterSpacing: 0.0,
    );

    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Color.fromARGB(255, 255, 248, 241),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color.fromARGB(255, 237, 86, 86),
          title: Text(
            'Leaderboard',
            style: leaderboardStyle,
          ),
          actions: [],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            children: [
              //Podium Container
              Consumer3<GroupModel, EventModel, UserModel>(builder:
                  (context, myGroupModel, myEventModel, myUserModel, child) {
                //Loading in the lists and then creating podiumList of top 3
                final List<UpdateLeaderDataUserDto> list =
                    myEventModel.getTopPlayersForEvent('', 1000);

                list.sort((a, b) => b.score.compareTo(a.score));
                UpdateLeaderDataUserDto empty =
                    UpdateLeaderDataUserDto.fromJson({
                  "userId": " ",
                  "username": " ",
                  "score": 0,
                });

                // Creating list to be displayed within the podium (filled with empty users if lists length is less than 3)
                List<UpdateLeaderDataUserDto> fullList = List.from(list);

                int iterTillFull = 3 - fullList.length;
                if (fullList.length < 3) {
                  for (int i = 0; i < iterTillFull; i++) {
                    fullList.add(empty);
                  }
                }

                List<UpdateLeaderDataUserDto> podiumList =
                    fullList.sublist(0, 3);

                // Booleans representing whether the current player is in the podium for highlighting purposes
                bool firstPodiumUser = podiumList.length > 0 &&
                    podiumList[0].userId == myUserModel.userData?.id;

                bool secondPodiumUser = podiumList.length > 1 &&
                    podiumList[1].userId == myUserModel.userData?.id;

                bool thirdPodiumUser = podiumList.length > 2 &&
                    podiumList[2].userId == myUserModel.userData?.id;

                return Container(
                  width: 328,
                  height: 213,
                  margin: EdgeInsets.only(top: 24, left: 25),
                  child: Row(children: [
                    Column(
                      children: [
                        SizedBox(height: 26),
                        podiumList.length > 1
                            ? podiumCell(context, podiumList[1].username)
                            : podiumCell(context, ""),
                        SizedBox(height: 12),
                        SecondPodium(
                            context, podiumList[1].score, secondPodiumUser),
                      ],
                    ),
                    SizedBox(width: 5),
                    Column(
                      children: [
                        podiumList.length > 0
                            ? podiumCell(context, podiumList[0].username)
                            : podiumCell(context, ""),
                        SizedBox(height: 12),
                        FirstPodium(
                            context, podiumList[0].score, firstPodiumUser),
                      ],
                    ),
                    SizedBox(width: 5),
                    Column(
                      children: [
                        SizedBox(height: 50),
                        podiumList.length > 2
                            ? podiumCell(context, podiumList[2].username)
                            : podiumCell(context, ""),
                        SizedBox(height: 12),
                        ThirdPodium(
                            context, podiumList[2].score, thirdPodiumUser),
                      ],
                    ),
                  ]),
                );
              }),
              SizedBox(height: 5),
              //Leaderboard Container
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 33.0, right: 8.0, top: 1.0),
                  child: Consumer3<GroupModel, EventModel, UserModel>(
                    builder: (context, myGroupModel, myEventModel, myUserModel,
                        child) {
                      // Use this line below to retrieve actual data
                      final List<UpdateLeaderDataUserDto> list =
                          myEventModel.getTopPlayersForEvent('', 1000);

                      // Dynamic Positions in leaderboard based on number of inputs
                      int position = 1;
                      if (list.length > 3) {
                        position = 4;
                      }

                      list.sort((a, b) => b.score.compareTo(a.score));

                      // Dynamic Skip Number (More than 3 users: Dont display those top 3 in the leaderboard)
                      int skipNumber = 3;
                      if (list.length < 3) {
                        skipNumber = 0;
                      }

                      return Container(
                        width: 345.0,
                        height: 446.0,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 170, 91, 0.15),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        child: Container(
                          width: 283.05,
                          height: 432.0,
                          child: ListView(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            children: [
                              for (UpdateLeaderDataUserDto user
                                  in list.skip(skipNumber))
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30.95, right: 30.95, top: 16.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10.0),
                                        topRight: Radius.circular(10.0),
                                        bottomLeft: Radius.circular(10.0),
                                        bottomRight: Radius.circular(10.0),
                                      ),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x40000000),
                                          offset:
                                              Offset(0.0, 1.7472529411315918),
                                          blurRadius: 6.989011764526367,
                                        ),
                                      ],
                                    ),
                                    child: leaderBoardCell(
                                      context,
                                      user.username,
                                      position++,
                                      user.score,
                                      user.userId == myUserModel.userData?.id,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
