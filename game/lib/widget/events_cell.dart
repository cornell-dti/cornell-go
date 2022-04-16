import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

String timeToTimeString(DateTime time) {
  final diff = time.difference(DateTime.now());
  if (diff.inDays > 0) {
    return diff.inDays.toString() + " Days";
  } else if (diff.inHours > 0) {
    return diff.inHours.toString() + " Hours";
  } else if (diff.inMinutes > 0) {
    return diff.inMinutes.toString() + " Minutes";
  } else {
    return diff.inSeconds.toString() + " Seconds";
  }
}

Widget eventsCell(
    context,
    String place,
    String date,
    String description,
    bool completed,
    bool current,
    DateTime? time,
    String reward,
    int rewardNum,
    int people,
    String imgpath) {
  var placeStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white);
  var timeStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 20, color: Colors.white);
  var dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  var descriptionStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 10, color: Colors.white);
  var rewardStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 15, color: Colors.white);
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        RotatedBox(
          quarterTurns: 3,
          child: Container(
              child: Text(
            date,
            style: dateStyle,
          )),
        ),
        Expanded(
          child: Container(
              decoration: BoxDecoration(
                  border: current
                      ? Border.all(color: Colors.greenAccent, width: 2.0)
                      : null,
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(imgpath),
                      fit: BoxFit.cover,
                      opacity: .5)),
              height: 150,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: [
                  Row(children: [
                    Container(
                        child: Text(
                      place,
                      style: placeStyle,
                      textAlign: TextAlign.left,
                    )),
                    Expanded(
                      child: Container(
                          alignment: Alignment.topRight,
                          child: (people == -1 && !completed
                              ? Container()
                              : (completed
                                  ? Icon(Icons.star,
                                      color: Colors.yellow, size: 25)
                                  : Icon(Icons.people,
                                      color: Colors.white, size: 25)))),
                    ),
                    Container(
                        child: Text(
                      people < 0 || completed ? "" : " ${people}",
                      style: placeStyle,
                    ))
                  ]),
                  Expanded(
                      child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        width: 150,
                        alignment: Alignment.topLeft,
                        child: Text(
                          description,
                          style: descriptionStyle,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  )),
                  Row(children: [
                    Container(
                        child: StreamBuilder(
                            stream: Stream.periodic(Duration(seconds: 1)),
                            builder: (builder, value) => Text(
                                  time == null
                                      ? ""
                                      : "${timeToTimeString(time)} Left",
                                  style: timeStyle,
                                ))),
                    Expanded(
                      child: Container(
                          child: Column(children: [
                        Container(
                            alignment: Alignment.bottomRight,
                            child: Text(reward, style: rewardStyle)),
                        Container(
                            alignment: Alignment.bottomRight,
                            child: Text(
                                rewardNum == 0
                                    ? ""
                                    : (time == null
                                        ? "∞ Rewards"
                                        : "${rewardNum} Rewards Left"),
                                style: rewardStyle))
                      ])),
                    )
                  ]),
                ]),
              )),
        )
      ]));
}
