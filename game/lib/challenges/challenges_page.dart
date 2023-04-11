import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'challenge_cell_new.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final cells = [
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'), false),
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'), true),
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'), false),
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'), true),
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
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.zero,
                    color: Color.fromARGB(76, 217, 217, 217),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        Icons.tune,
                        color: Color.fromARGB(204, 0, 0, 0),
                        size: 12,
                      ),
                      label: Text(
                        "filter",
                        style: TextStyle(
                          color: Color.fromARGB(204, 0, 0, 0),
                          fontSize: 12,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
