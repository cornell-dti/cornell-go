import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

List<Widget> generate_progress(tasks, tasks_completed) {
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
          Container(
              height: 20,
              child: Row(
                children: generate_progress(tasks, tasks_completed),
              )),
          Container(
            padding: EdgeInsets.all(32.0),
            height: 120,
            child: Center(
              child: Text(
                "Find the Location of this cafe on the arts quad",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(204, 0, 0, 0),
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Inter"),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Expanded(
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: Image.network(
                      'https://picsum.photos/500/1500',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                Container(
                  height: 100,
                  width: 500,
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 238, 238, 238),
                      borderRadius:
                          BorderRadius.all(Radius.elliptical(400, 200))),
                ),
                Container(
                  child: Text(
                    "${distance} mi",
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Inter"),
                  ),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
