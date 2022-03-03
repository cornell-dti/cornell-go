import 'package:flutter/material.dart';

Widget visitedPlacesCell(context, place, date, points, imgpath) {
  var placeStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white);
  var pointsStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 10, color: Colors.white);
  var dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 8,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            image: AssetImage(imgpath),
            fit: BoxFit.cover,
          )),
          height: 80,
          child: Column(
            children: [
              Container(child: Text(place, style: placeStyle)),
              Container(child: Text("${points} Points", style: pointsStyle)),
              Container(
                  child: Text(
                date,
                style: dateStyle,
              )),
            ],
          )));
}
