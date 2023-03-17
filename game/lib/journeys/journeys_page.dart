import 'package:flutter/material.dart';
import 'package:game/journeys/journey_cell.dart';

class JourneysPage extends StatefulWidget {
  const JourneysPage({Key? key}) : super(key: key);

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  final cells = [
    JourneyCell("journey", "hi", 2, 1),
    JourneyCell("journey", "hi", 5, 3),
    JourneyCell("journey", "hi", 4, 1),
    JourneyCell("journey", "hi", 0, 0),
  ];
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
              child: ListView.separated(
                itemCount: cells.length,
                itemBuilder: (context, index) {
                  return cells[index];
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 10);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
