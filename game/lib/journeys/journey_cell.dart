import 'package:flutter/material.dart';

class JourneyCell extends StatefulWidget {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;

  const JourneyCell(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _JourneyCellState(
      journeyName,
      description,
      locationCount,
      numberCompleted,
      isCompleted,
      difficulty,
      points,
      challenge_points);
}

class _JourneyCellState extends State<JourneyCell> {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;
  _JourneyCellState(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
            context: context,
            builder: (_) => JourneyPreview(
                journeyName,
                description,
                locationCount,
                numberCompleted,
                isCompleted,
                difficulty,
                points,
                challenge_points));
      },
      child: Container(
        color: Color.fromARGB(51, 217, 217, 217),
        height: 180.0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompleted)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: Color.fromARGB(255, 71, 71, 71),
                          fontSize: 10,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                height: 18,
                child: Text(
                  locationCount == 1
                      ? '${locationCount} location'
                      : '${locationCount} locations',
                  style: TextStyle(
                    color: Color.fromARGB(153, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Container(
                height: 27,
                child: Text(
                  journeyName,
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 18,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              Container(
                height: 18,
                child: Text(
                  description,
                  style: TextStyle(
                    color: Color.fromARGB(179, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Container(
                  height: 10.0,
                  width: double.infinity,
                  color: Color.fromARGB(255, 255, 255, 255),
                  child: FractionallySizedBox(
                    alignment: Alignment.topLeft,
                    widthFactor: (locationCount > 0
                        ? numberCompleted / locationCount
                        : 0),
                    child: Container(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JourneyPreview extends StatelessWidget {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  const JourneyPreview(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
          height: 300,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(imgPath), fit: BoxFit.cover)),
                height: 100,
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    SizedBox(
                      height: 20,
                      child: TextButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(backgroundColor),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: backgroundColor)))),
                        onPressed: () {},
                        child: Text(difficulty),
                      ),
                    )
                  ],
                ),
              ),
              Text(journeyName),
              Text(description),
              Row(),
              Row(),
            ],
          )),
    );
  }
}
