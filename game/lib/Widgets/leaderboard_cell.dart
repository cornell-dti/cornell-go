import 'package:flutter/material.dart';

Widget leaderBoardCell(context, name, position, points, isUser) {
  Color Carnelian = Color(0xFFB31B1B);
  var posStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 40,
      color: (isUser) ? Carnelian : Colors.white);
  var nameStyle = TextStyle(
      fontWeight: (isUser) ? FontWeight.w900 : FontWeight.w800,
      fontSize: 22,
      color: (isUser) ? Carnelian : Colors.white);
  var pointStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 18,
      color: (isUser) ? Carnelian : Colors.white,
      fontStyle: FontStyle.italic);
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Row(
            children: [
              Container(
                child: Row(
                  children: [
                    Text(position, style: posStyle),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Icon(Icons.camera_alt_rounded, color: Carnelian),
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Container(
                  child: Text(name, style: nameStyle),
                ),
              ),
            ],
          ),
          Container(
            child: Text(
              points,
              style: pointStyle,
            ),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    ),
  );
}
