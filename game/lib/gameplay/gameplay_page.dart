import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:game/model/challenge_model.dart';
import 'gameplay_map.dart';
import 'package:provider/provider.dart';

// Returns widget that fills based on tasks and tasks_completed.
List<Widget> progressBar(int tasks, int tasks_completed) {
  List<Widget> progress_blocks = [];
  for (var i = 0; i < tasks; i++) {
    if (i < tasks_completed) {
      progress_blocks.add(Expanded(
          child: Container(height: 20, color: Color.fromARGB(204, 0, 0, 0))));
    } else {
      progress_blocks.add(Expanded(
          child: Container(
              height: 20, color: Color.fromARGB(204, 217, 217, 217))));
    }
  }
  return progress_blocks;
}

class GameplayPage extends StatefulWidget {
  const GameplayPage({Key? key}) : super(key: key);

  @override
  State<GameplayPage> createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage> {
  @override
  final tasks = 6;
  final tasks_completed = 2;
  final distance = .8;

  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //SafeArea to avoid notch overlap
          SafeArea(child:
              Consumer<ChallengeModel>(builder: (context, challengeModel, _) {
            var challenge = challengeModel.getChallengeById("123");
            print(challenge);
            return Container(
              padding: EdgeInsets.all(32.0),
              height: 120,
              child: Center(
                child: Text(
                  "Find the Location of this cafe on the arts quad",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            );
          })),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                //Event Picture and google map
                Expanded(
                  child: Stack(alignment: Alignment.topRight, children: [
                    Container(
                      height: double.infinity,
                      width: double.infinity,
                      //Change to challenge picture
                      child: Image.network(
                        'https://picsum.photos/500/1500',
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(top: 15, right: 15),
                      child: Text(
                        "MAP",
                        style:
                            TextStyle(fontSize: 21, color: Color(0xFFED5656)),
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(0, 3), // shadow direction: bottom
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                Container(
                  height: 100,
                  width: 500,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.elliptical(500, 100)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 75),
                  child: Consumer<ChallengeModel>(
                      builder: (context, challengeModel, _) {
                    return Text(
                      "${distance} miles away",
                      style: TextStyle(fontSize: 21, color: Color(0xFFED5656)),
                    );
                  }),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(0, 3), // shadow direction: bottom
                      ),
                    ],
                  ),
                ),
                Container(
                    height: 20,
                    child: Row(
                      children: progressBar(tasks, tasks_completed),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
