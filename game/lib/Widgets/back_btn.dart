import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget backBtn(scaffoldKey, context) {
  Color Carnelian = Color(0xFFB31B1B);
  return Container(
    margin: EdgeInsets.only(top: 75, left: 25),
    child: FloatingActionButton(
      onPressed: () {
        Navigator.pop(context);
      },
      backgroundColor: Carnelian,
      child: const Icon(Icons.arrow_back),
    ),
  );
}
