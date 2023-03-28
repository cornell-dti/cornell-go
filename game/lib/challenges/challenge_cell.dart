import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChallengeCell extends StatefulWidget {
  final String place;
  final String date;
  final String imgPath;
  final bool current;
  final bool notVisited;

  ChallengeCell(
      this.place, this.date, this.imgPath, this.current, this.notVisited);

  @override
  State<StatefulWidget> createState() => ChallengeCellState();
}

class ChallengeCellState extends State<ChallengeCell> {
  final placeStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white);
  final dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  bool visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(milliseconds: 500),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              RotatedBox(
                quarterTurns: 3,
                child: Container(
                    child: Text(
                  this.widget.notVisited ? "" : this.widget.date,
                  style: dateStyle,
                )),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: !this.widget.current && this.widget.notVisited
                              ? Colors.black
                              : null,
                          image: !this.widget.current && this.widget.notVisited
                              ? null
                              : DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      this.widget.imgPath),
                                  fit: BoxFit.cover,
                                  opacity: .5)),
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            child: this.widget.notVisited
                                ? Text("Not Visited Yet...", style: placeStyle)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(
                                          child: Text(this.widget.place,
                                              style: placeStyle)),
                                      Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: this.widget.notVisited
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
                        opacity: this.widget.current ? 1 : 0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.greenAccent, width: 2.0),
                          ),
                          height: 80,
                        ))
                  ],
                ),
              )
            ])));
  }
}
