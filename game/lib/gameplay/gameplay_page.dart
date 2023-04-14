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
            child: Container(
                child: Image.network(
              'https://picsum.photos/250?image=9',
              fit: BoxFit.fitWidth,
            )),
          ),
        ],
      ),
    );
  }
}
