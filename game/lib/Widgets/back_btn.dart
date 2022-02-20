import 'package:simple_animations/simple_animations.dart';
import 'package:flutter/material.dart';

Widget backBtn(scaffoldKey, context, text) {
  var toFit = MediaQuery.of(context).size.width - 40;
  Color Carnelian = Color(0xFFB31B1B);
  return Align(
    alignment: Alignment.topLeft,
    child: Container(
      margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height / 8, left: 25),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlayAnimation<double>(
            tween: Tween(begin: 0, end: toFit),
            duration: const Duration(milliseconds: 500),
            builder: (context, child, value) {
              return Positioned(
                left: 10,
                child: Container(
                  alignment: Alignment.center,
                  height: 56,
                  width: value,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                      color: Carnelian),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 12.0, bottom: 12.0, right: 12.0, left: 28.0),
                    child: Text(
                      text,
                      style: TextStyle(
                          color: Colors.white.withOpacity(value / toFit),
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 5,
            child: FloatingActionButton(
              elevation: 0,
              onPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: Carnelian,
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    ),
  );
}
