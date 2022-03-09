import 'package:flutter/material.dart';

Widget visitedPlacesCell(context, place, date, points, imgpath) {
  var placeStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white);
  var pointsStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 20, color: Colors.white);
  var dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Colors.white,
      fontStyle: FontStyle.italic);
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
                  image: DecorationImage(
                      image: AssetImage(imgpath),
                      fit: BoxFit.cover,
                      opacity: .5)),
              height: 80,
              child: Column(children: [
                Container(child: Text(place, style: placeStyle)),
                Container(child: Text("${points} Points", style: pointsStyle))
              ])),
        )
      ]));
}
