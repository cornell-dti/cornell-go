import 'package:flutter/material.dart';
import 'package:game/constants/constants.dart';

Widget navBtn(scaffoldKey, context) {
  return Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height / 8,
          left: 25,
        ),
        child: FloatingActionButton(
          heroTag: "nav_menu_btn",
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
          backgroundColor: AppColors.carnelian,
          child: const Icon(Icons.menu),
        ),
      ),
    ),
  );
}
