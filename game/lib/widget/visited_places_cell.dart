import 'package:flutter/material.dart';

final defaultStyle =
    TextStyle(fontWeight: FontWeight.normal, fontSize: 20, color: Colors.white);
Widget visitedPlacesCell(context, place, date, points, imgpath) {
  var placeStyle =
      defaultStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 25);
  var pointsStyle = defaultStyle;
  var dateStyle =
      defaultStyle.copyWith(fontSize: 15, fontStyle: FontStyle.italic);
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
