import 'package:flutter/material.dart';
import 'package:game/journeys/journey_cell.dart';

class JourneysPage extends StatefulWidget {
  const JourneysPage({Key? key}) : super(key: key);

  @override
  State<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends State<JourneysPage> {
  final cells = [
    JourneyCell(
      "DTI Scavenger Hunt",
      "Scavenger hunt during All Hands on 2/18",
      10,
      5,
      false,
      "normal",
      15,
      3,
    ),
    JourneyCell(
      "DTI Scavenger Hunt",
      "Scavenger hunt during All Hands on 2/18",
      10,
      0,
      false,
      "normal",
      15,
      3,
    ),
    JourneyCell(
      "Cornell Cafés",
      "Get your coffee fix at these top cafés on campus.",
      6,
      6,
      true,
      "normal",
      15,
      3,
    ),
    JourneyCell(
      "journey",
      "hi",
      0,
      0,
      false,
      "normal",
      15,
      3,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              height: 30,
              color: Color.fromARGB(51, 217, 217, 217),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color.fromARGB(204, 0, 0, 0),
                    size: 12,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(1.0))),
                  labelText: "Search a challenge name, location, etc...",
                  labelStyle: TextStyle(
                    color: Color.fromARGB(76, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: Text("filter"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(0),
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
