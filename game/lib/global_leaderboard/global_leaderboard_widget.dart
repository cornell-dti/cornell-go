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

    int playerPosition = 0;
    var scoreList = [];

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color.fromARGB(255, 255, 248, 241),
      appBar: AppBar(
        toolbarHeight: MediaQuery.sizeOf(context).height * 0.1,
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 237, 86, 86),
        flexibleSpace: FlexibleSpaceBar(
          title: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).height * 0.01,
            ),
            child: Text('Leaderboard', style: leaderboardStyle),
          ),
          centerTitle: true,
        ),
        actions: [],
      ),
      body: Consumer3<GroupModel, EventModel, UserModel>(
        builder: (context, myGroupModel, myEventModel, myUserModel, child) {
          //Loading in the lists and then creating podiumList of top 3
          final List<LeaderDto>? list = myEventModel.getTopPlayersForEvent(
            '',
            1000,
          );

          if (list == null) return Center(child: CircularProgressIndicator());

          LeaderDto empty = LeaderDto(userId: " ", username: " ", score: 0);

          // Creating list to be displayed within the podium (filled with empty users if lists length is less than 3)
          List<LeaderDto> fullList = List.from(list);

          int iterTillFull = 3 - fullList.length;
          if (fullList.length < 3) {
            for (int i = 0; i < iterTillFull; i++) {
              fullList.add(empty);
            }
          }
          // Leaderboard starts at 4th position because first three already in podium
          int position = 4;

          List<LeaderDto> podiumList = fullList.sublist(0, 3);

          bool firstPodiumUser = podiumList.length > 0 &&
              podiumList[0].userId == myUserModel.userData?.id;

          bool secondPodiumUser = podiumList.length > 1 &&
              podiumList[1].userId == myUserModel.userData?.id;

          bool thirdPodiumUser = podiumList.length > 2 &&
              podiumList[2].userId == myUserModel.userData?.id;

          return Center(
            //Podium Container
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.sizeOf(context).width * 0.05,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          podiumList.length > 1
                              ? podiumCell(
                                  context,
                                  podiumList[1].username,
                                  secondPodiumUser,
                                )
                              : podiumCell(context, "", false),
                          SecondPodium(
                            context,
                            podiumList[1].score,
                            secondPodiumUser,
                          ),
                        ],
                      ),
                      SizedBox(width: MediaQuery.sizeOf(context).width * 0.03),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          podiumList.length > 0
                              ? podiumCell(
                                  context,
                                  podiumList[0].username,
                                  firstPodiumUser,
                                )
                              : podiumCell(context, "", false),
                          FirstPodium(
                            context,
                            podiumList[0].score,
                            firstPodiumUser,
                          ),
                        ],
                      ),
                      SizedBox(width: MediaQuery.sizeOf(context).width * 0.03),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          podiumList.length > 2
                              ? podiumCell(
                                  context,
                                  podiumList[2].username,
                                  thirdPodiumUser,
                                )
                              : podiumCell(context, "", false),
                          ThirdPodium(
                            context,
                            podiumList[2].score,
                            thirdPodiumUser,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
                Expanded(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 0.88,
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 170, 91, 0.15),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    // Ranking List
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      children: [
                        for (LeaderDto user in list.skip(3))
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                left: 16,
                                right: 16,
                              ),
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
                                      offset: Offset(0.0, 1.745),
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
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
