import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget navBtn(scaffoldKey) {
  Color Carnelian = Color(0xFFB31B1B);
  return Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        margin: EdgeInsets.only(top: 75, left: 25),
        child: FloatingActionButton(
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
          backgroundColor: Carnelian,
          child: const Icon(Icons.menu),
        ),
      ),
    ),
  );
}
