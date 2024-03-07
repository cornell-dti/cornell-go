import 'package:flutter/material.dart';
import 'challenge_cell_new.dart';
import 'package:game/journeys/filter_form.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  void openFilter() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (
          BuildContext context,
        ) {
          return FilterForm();
        });
  }

  final cells = [
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        false,
        "Find this famous statue!",
        "Easy",
        15,
        3),
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        true,
        "Find this famous statue!",
        "Normal",
        15,
        3),
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        false,
        "Find this famous statue!",
        "Hard",
        15,
        3),
    ChallengeCell(
        "ARTS QUAD",
        "Statue on the Arts Quad",
        Image.network('https://picsum.photos/250?image=9'),
        true,
        "Find this famous statue!",
        "Challenging",
        15,
        3),
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
                    height: 30,
                    child: TextButton.icon(
                      onPressed: openFilter,
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: Color.fromARGB(255, 0, 0, 0),
                        size: 20.0,
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(153, 217, 217, 217)),
                        padding: MaterialStateProperty.all(
                          EdgeInsets.only(right: 16.0, left: 16.0),
                        ),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3.0),
                        )),
                      ),
                      label: Text(
                        "Filter By",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 15,
                          fontFamily: 'Inter',
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
