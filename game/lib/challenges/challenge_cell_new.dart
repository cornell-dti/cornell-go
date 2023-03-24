import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class ChallengeCell extends StatelessWidget {
  final String location;
  final String challengeName;
  final Image thumbnail;
  const ChallengeCell(this.location, this.challengeName, this.thumbnail,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(51, 217, 217, 217),
      height: 85.0,
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(child: thumbnail),
              Column(
                children: [
                  Container(
                    child: Text(
                      location,
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 18,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  Text(
                    challengeName,
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 18,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              )
            ],
          )),
    );
  }
}
