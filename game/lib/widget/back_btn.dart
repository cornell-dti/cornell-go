import 'package:simple_animations/simple_animations.dart';
import 'package:flutter/material.dart';
import 'package:game/constants/constants.dart';

Widget backBtn(scaffoldKey, context, text) {
  var toFit = MediaQuery.of(context).size.width - 35;
  return Align(
    alignment: Alignment.topLeft,
    child: Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height / 8,
        left: 25,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlayAnimationBuilder<double>(
            tween: Tween(begin: 0, end: toFit),
            duration: const Duration(milliseconds: 400),
            builder: (child, value, _) {
              return Positioned(
                left: 10,
                child: Container(
                  alignment: Alignment.center,
                  height: 56,
                  width: value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    color: AppColors.carnelian,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12.0,
                      bottom: 12.0,
                      right: 12.0,
                      left: 12.0,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(value / toFit),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 5,
            child: FloatingActionButton(
              heroTag: "back_btn_$text",
              elevation: 2,
              onPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: AppColors.carnelian,
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    ),
  );
}
