import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class ChallengeCell extends StatelessWidget {
  final String location;
  final String challengeName;
  final Image thumbnail;
  final bool isCompleted;
  const ChallengeCell(
      this.location, this.challengeName, this.thumbnail, this.isCompleted,
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
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4.6)),
                child: thumbnail,
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          color: Color.fromARGB(204, 0, 0, 0),
                          child: Text(
                            location,
                            style: TextStyle(
                              color: Color.fromARGB(230, 255, 255, 255),
                              fontSize: 8,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                        if (isCompleted) ...[
                          Expanded(
                            child: Row(
                              children: [
                                Spacer(),
                                Text(
                                  "COMPLETED",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 71, 71, 71),
                                    fontSize: 10,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    challengeName,
                    style: TextStyle(
                      color: Color.fromARGB(204, 0, 0, 0),
                      fontSize: 16.5,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
