import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/widget/back_btn.dart';
import 'package:game/widget/leaderboard_cell.dart';
import 'package:game/widget/podium_cell.dart';
import 'package:game/widget/leaderboard_user_cell.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * This widget defines the leaderboard page. 
 */
class GlobalLeaderboardWidget extends StatefulWidget {
  GlobalLeaderboardWidget({Key? key}) : super(key: key);

  @override
  _GlobalLeaderboardWidgetState createState() =>
      _GlobalLeaderboardWidgetState();
}

class PodiumWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 328,
      height: 112,
      child: SvgPicture.asset(
        'assets/images/podium.svg',
        semanticsLabel: 'Podium',
      ),
    ));
  }
}

/**
 * This widget is the mutable state of the global leaderboard. Currently, there 
 * are sample users, but it gets the top 10 users and displays them on the leaderboard!
 */
class _GlobalLeaderboardWidgetState extends State<GlobalLeaderboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<UpdateLeaderDataUserDto> sampleUsers = [
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user1",
      "username": "user1_username",
      "score": 100,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user2",
      "username": "user2_username",
      "score": 85,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user3",
      "username": "user3_username",
      "score": 120,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user4",
      "username": "user4_username",
      "score": 75,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user5",
      "username": "user5_username",
      "score": 95,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user6",
      "username": "user6_username",
      "score": 110,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user7",
      "username": "user7_username",
      "score": 90,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user8",
      "username": "user8_username",
      "score": 80,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user9",
      "username": "user9_username",
      "score": 70,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user10",
      "username": "user10_username",
      "score": 115,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user11",
      "username": "user11_username",
      "score": 60,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user12",
      "username": "user12_username",
      "score": 130,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user13",
      "username": "user13_username",
      "score": 55,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user14",
      "username": "user14_username",
      "score": 105,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user15",
      "username": "user15_username",
      "score": 75,
    }),
  ];

  String currentUserId = "user1";

  UserDto sampleUserData = UserDto.fromJson({
    "user": {
      "id": "user13",
      "username": "example_username",
      "major": "Computer Science",
      "year": "Senior",
      "score": 100,
      "groupId": "group123",
      "rewardIds": ["reward1", "reward2"],
      "trackedEventIds": ["event1", "event2"],
      "authType": "google"
    }
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
              Container(
                height: 29.0,
                margin: EdgeInsets.only(top: 46.0),
                child: Text(
                  "Leaderboard",
                  style: leaderboardStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                  padding:
                      const EdgeInsets.only(left: 130.0, right: 17.0, top: 25),
                  child: Row(
                    children: [
                      Container(
                          child: podiumCell(context, "test1", 1, 300, false)),
                      Container(
                          child: podiumCell(context, "test2", 2, 200, false)),
                      Container(
                          child: podiumCell(context, "test3", 1, 190, false)),
                    ],
                  )),
              Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 25),
                  child: PodiumWidget()),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, right: 8.0, top: 10.0),
                  child: Consumer3<GroupModel, EventModel, UserModel>(
                    builder: (context, myGroupModel, myEventModel, myUserModel,
                        child) {
                      int position = 4;
                      //if (myGroupModel.curEventId == null) return ListView();
                      // final List<UpdateLeaderDataUserDto> list =
                      //     myEventModel.getTopPlayersForEvent('', 1000);
                      final List<UpdateLeaderDataUserDto> list = sampleUsers;
                      list.sort((a, b) => b.score.compareTo(a.score));
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
                                for (UpdateLeaderDataUserDto user in list)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: Container(
                                      decoration: BoxDecoration(
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
