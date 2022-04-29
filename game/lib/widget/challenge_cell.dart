import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget challengeCell(
    context, place, date, imgpath, current, notVisited, noSkipping) {
  var placeStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white);
  var dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        RotatedBox(
          quarterTurns: 3,
          child: Container(
              child: Text(
            notVisited ? "" : date,
            style: dateStyle,
          )),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: noSkipping && !current && notVisited
                        ? Colors.black
                        : null,
                    image: noSkipping && !current && notVisited
                        ? null
                        : DecorationImage(
                            image: CachedNetworkImageProvider(imgpath),
                            fit: BoxFit.cover,
                            opacity: .5)),
                height: 80,
                child: Column(
                  children: [
                    Container(
                      child: notVisited
                          ? Text("Not Visited Yet...", style: placeStyle)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(child: Text(place, style: placeStyle)),
                                Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: notVisited
                                      ? null
                                      : Icon(Icons.star,
                                          color: Colors.yellow, size: 25),
                                )
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                  opacity: current ? 1 : 0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 2.0),
                    ),
                    height: 80,
                  ))
            ],
          ),
        )
      ]));
}
