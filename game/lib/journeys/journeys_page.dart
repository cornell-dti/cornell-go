import 'package:flutter/material.dart';
import 'package:game/journeys/journey_cell.dart';

class JourneysPage extends StatefulWidget {
  const JourneysPage({Key? key}) : super(key: key);

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Container(child: Text("search")),
            Container(child: Text("filter/sort")),
            Expanded(
              child: ListView(
                children: [
                  JourneyCell(),
                  JourneyCell(),
                  JourneyCell(),
                  JourneyCell(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
