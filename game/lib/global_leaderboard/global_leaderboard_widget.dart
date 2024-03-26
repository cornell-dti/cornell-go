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
 * This widget is the mutable state of the global leaderboard. Currently, there 
 * are sample users, but it gets the top 10 users and displays them on the leaderboard!
 */
class _GlobalLeaderboardWidgetState extends State<GlobalLeaderboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  //SampleUsers is mock leaderboard data since the users fetch is not working properly.
  List<LeaderDto> sampleUsers = [
    LeaderDto.fromJson({
      "userId": "user1",
      "username": "user1_username",
      "score": 100,
    }),
    LeaderDto.fromJson({
      "userId": "user2",
      "username": "user2_username",
      "score": 85,
    }),
    LeaderDto.fromJson({
      "userId": "user3",
      "username": "user3_username",
      "score": 120,
    }),
    LeaderDto.fromJson({
      "userId": "user4",
      "username": "user4_username",
      "score": 75,
    }),
    LeaderDto.fromJson({
      "userId": "user5",
      "username": "user5_username",
      "score": 95,
    }),
    LeaderDto.fromJson({
      "userId": "user6",
      "username": "user6_username",
      "score": 110,
    }),
    LeaderDto.fromJson({
      "userId": "user7",
      "username": "user7_username",
      "score": 90,
    }),
    LeaderDto.fromJson({
      "userId": "user8",
      "username": "user8_username",
      "score": 80,
    }),
    LeaderDto.fromJson({
      "userId": "user9",
      "username": "user9_username",
      "score": 70,
    }),
    LeaderDto.fromJson({
      "userId": "user10",
      "username": "user10_username",
      "score": 115,
    }),
    LeaderDto.fromJson({
      "userId": "user11",
      "username": "user11_username",
      "score": 60,
    }),
    LeaderDto.fromJson({
      "userId": "user12",
      "username": "user12_username",
      "score": 130,
    }),
    LeaderDto.fromJson({
      "userId": "user13",
      "username": "user13_username",
      "score": 55,
    }),
    LeaderDto.fromJson({
      "userId": "user14",
      "username": "user14_username",
      "score": 105,
    }),
    LeaderDto.fromJson({
      "userId": "user15",
      "username": "user15_username",
      "score": 75,
    }),
  ];

  //Thhis user represents the users status. This is mock data for now.
  UserDto sampleUserData = UserDto.fromJson({
    "id": "user6",
    "username": "example_username",
    "major": "Computer Science",
    "year": "Senior",
    "score": 100,
    "groupId": "group123",
    "trackedEvents": ["event1", "event2"],
    "authType": "google"
  });

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
        backgroundColor: Color(0xFFE95755),
        body: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            children: [
              //Title Container
              Container(
                height: 29.0,
                margin: EdgeInsets.only(top: 51.0, left: 25),
                child: Text(
                  "Leaderboard",
                  style: leaderboardStyle,
                ),
              ),
              //Podium Container
              Consumer3<GroupModel, EventModel, UserModel>(builder:
                  (context, myGroupModel, myEventModel, myUserModel, child) {
                //Loading in the lists and then creating podiumList of top 3
                final List<LeaderDto> list =
                    myEventModel.getTopPlayersForEvent('', 1000);
                ;
                list.sort((a, b) => b.score.compareTo(a.score));
                List<LeaderDto> podiumList =
                    list.sublist(0, list.length >= 3 ? 3 : list.length);
                return Container(
                  width: 328,
                  height: 213,
                  margin: EdgeInsets.only(top: 24, left: 25),
                  child: Row(children: [
                    Column(
                      children: [
                        SizedBox(height: 26),
                        podiumList.length > 1
                            ? podiumCell(context, podiumList[1].username,
                                podiumList[1].score)
                            : podiumCell(context, "", 0),
                        SizedBox(height: 12),
                        (podiumList.length > 1 &&
                                podiumList[1].userId == sampleUserData.id)
                            ? SecondPodiumYellow()
                            : SecondPodiumRed(),
                      ],
                    ),
                    SizedBox(width: 5),
                    Column(
                      children: [
                        podiumList.length > 0
                            ? podiumCell(context, podiumList[0].username,
                                podiumList[0].score)
                            : podiumCell(context, "", 0),
                        SizedBox(height: 12),
                        (podiumList.length > 0 &&
                                podiumList[0].userId == sampleUserData.id)
                            ? FirstPodiumYellow()
                            : FirstPodiumRed(),
                      ],
                    ),
                    SizedBox(width: 5),
                    Column(
                      children: [
                        SizedBox(height: 50),
                        podiumList.length > 2
                            ? podiumCell(context, podiumList[2].username,
                                podiumList[2].score)
                            : podiumCell(context, "", 0),
                        SizedBox(height: 12),
                        (podiumList.length > 2 &&
                                podiumList[2].userId == sampleUserData.id)
                            ? ThirdPodiumYellow()
                            : ThirdPodiumRed(),
                      ],
                    ),
                  ]),
                );
              }),
              //Leaderboard Container
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 33.0, right: 8.0, top: 1.0),
                  child: Consumer3<GroupModel, EventModel, UserModel>(
                    builder: (context, myGroupModel, myEventModel, myUserModel,
                        child) {
                      int position = 4;
                      // Use this line below to retrieve actual data
                      final List<LeaderDto> list =
                          myEventModel.getTopPlayersForEvent('', 1000);
                      // final List<LeaderDto> list = sampleUsers;
                      list.sort((a, b) => b.score.compareTo(a.score));
                      list.removeRange(0, list.length >= 3 ? 3 : list.length);
                      return Container(
                        width: 345.0,
                        height: 446.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        child: Container(
                          width: 283.05,
                          height: 432.0,
                          child: Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              children: [
                                for (LeaderDto user in list)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 30.95,
                                        right: 30.95,
                                        bottom: 16.0),
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
                                        user.userId == sampleUserData.id,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
