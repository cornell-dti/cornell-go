import 'package:flutter/material.dart';

Widget LatoText(String text, double fs, Color color, FontWeight fw) {
  return Text(
    text,
    style: TextStyle(
      fontFamily: 'Lato',
      color: color,
      fontWeight: fw,
      fontSize: fs,
    ),
  );
}
