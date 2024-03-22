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
  List<UpdateLeaderDataUserDto> sampleUsers = [
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user1",
      "username": "Brandon Lee",
      "score": 100,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user2",
      "username": "user2_username",
      "score": 85,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user3",
      "username": "Erica Lee",
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
      "username": "Michelle Dai",
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
      "username": "Lucy Yang",
      "score": 115,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user11",
      "username": "user11_username",
      "score": 60,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user12",
      "username": "David Martinez Lopez",
      "score": 130,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user13",
      "username": "user13_username",
      "score": 55,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user14",
      "username": "Lazim Jarif",
      "score": 105,
    }),
    UpdateLeaderDataUserDto.fromJson({
      "userId": "user15",
      "username": "user15_username",
      "score": 75,
    }),
  ];

  //Thhis user represents the users status. This is mock data for now.
  UserDto sampleUserData = UserDto.fromJson({
    "user": {
      // "id": "user6", or 12 or 10
      "id": "user6",
      "username": "example_username",
      "major": "Computer Science",
      "year": "Senior",
      "score": 100,
      "groupId": "group123",
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
                // ;
                // Load Sample Data
                // final List<UpdateLeaderDataUserDto> list = sampleUsers;

                // list.insertAll(0, sampleUsers);
                list.sort((a, b) => b.score.compareTo(a.score));
                UpdateLeaderDataUserDto empty =
                    UpdateLeaderDataUserDto.fromJson({
                  "userId": " ",
                  "username": " ",
                  "score": 0,
                });

                // Checking list length
                int l = list.length;
                // Ensure list has at least 3 elements, filling with defaults if necessary.
                if (l < 3) {
                  for (int i = 0; i < (3 - l); i++) {
                    list.add(empty);
                  }
                }

                // TODO: Should not be locked on 3
                List<UpdateLeaderDataUserDto> podiumList = list.sublist(0, 3);

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
                            ? podiumCell(context, podiumList[1].username,
                                podiumList[1].score)
                            : podiumCell(context, "", 0),
                        SizedBox(height: 12),
                        SecondPodium(
                            context, podiumList[1].score, secondPodiumUser),
                      ],
                    ),
                    SizedBox(width: 5),
                    Column(
                      children: [
                        podiumList.length > 0
                            // TODO: Change if not including username/score
                            ? podiumCell(context, podiumList[0].username,
                                podiumList[0].score)
                            : podiumCell(context, "", 0),
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
                            ? podiumCell(context, podiumList[2].username,
                                podiumList[2].score)
                            : podiumCell(context, "", 0),
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
                      int position = 0;
                      // Use this line below to retrieve actual data
                      final List<UpdateLeaderDataUserDto> list =
                          myEventModel.getTopPlayersForEvent('', 1000);

                      UpdateLeaderDataUserDto empty =
                          UpdateLeaderDataUserDto.fromJson({
                        "userId": "n",
                        "username": " ",
                        "score": 0,
                      });

                      list.sort((a, b) => b.score.compareTo(a.score));

                      // Checking list length
                      int l = list.length;
                      // Ensure list has at least 3 elements, filling with defaults if necessary.
                      if (l < 3) {
                        for (int i = 0; i < (3 - l); i++) {
                          list.add(empty);
                        }
                      }

                      print(list.length);

                      // Use this line to retrieve sample data
                      // List<UpdateLeaderDataUserDto> list = sampleUsers;
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
                          // width: 350,
                          height: 432.0,
                          child: ListView(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            children: [
                              // if (list.length > 3)
                              for (UpdateLeaderDataUserDto user in list)
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
                                      // Color.fromRGBO(255, 170, 91, 0.15),
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
