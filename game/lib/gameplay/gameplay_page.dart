import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:game/model/challenge_model.dart';
import 'gameplay_map.dart';
import 'package:provider/provider.dart';

class GameplayPage extends StatefulWidget {
  final String challengeId;

  const GameplayPage({Key? key, required this.challengeId}) : super(key: key);

  @override
  State<GameplayPage> createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeModel>(builder: (context, challengeModel, _) {
      var challenge = challengeModel.getChallengeById(widget.challengeId);

      return Scaffold(
        body: Column(
          children: [
            //SafeArea to avoid notch overlap
            SafeArea(
                child: Container(
                    padding: EdgeInsets.only(
                      left: 32,
                      right: 32,
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Left button action
                                  },
                                  child: Text('Leave Game',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF835A7C))),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F1F1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 8.0),
                                  child: const Text('Challenge',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFA4A4A4))),
                                ),
                              ]),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Find the Location of ${challenge?.description ?? ""}",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(top: 15),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Arts Quad',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF835A7C))),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF9EDDA),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15.0),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 8.0),
                                      child: const Text('Easy',
                                          style: TextStyle(
                                            fontSize: 12,
                                          )),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xFFFFC737), width: 3),
                                        color: Color(0xFFBD871F),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15.0),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 8.0),
                                      child: Text('100 pts',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFF1F1F1))),
                                    ),
                                    Text('0.0 Miles Away',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF58B171))),
                                  ]))
                        ]))),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Padding(
                      padding: EdgeInsets.only(top: 20), child: GameplayMap()),
                  Container(
                    margin: EdgeInsets.only(bottom: 70),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 237, 86, 86),
                        padding: EdgeInsets.only(
                            right: 15, left: 15, top: 10, bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // button's shape
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 16, //arbitrary large number
                                child: Container(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(
                                                "Nearly There!",
                                                style: TextStyle(
                                                    fontSize: 25,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )),
                                          Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 10),
                                              child: Text(
                                                  "Use a hint if needed, you are close!")),
                                          Center(
                                              child: ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: Text("Keep Trying")))
                                        ])));
                          },
                        );
                      },
                      child: Text(
                        "I've Arrived!",
                        style:
                            TextStyle(fontSize: 21, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
