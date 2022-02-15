import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget navBtn(scaffoldKey) {
  Color Carnelian = Color(0xFFB31B1B);
  return Container(
    margin: EdgeInsets.only(top: 75, left: 25),
    child: FloatingActionButton(
      onPressed: () {
        scaffoldKey.currentState?.openDrawer();
      },
      backgroundColor: Carnelian,
      child: const Icon(Icons.menu),
    ),
  );
}
