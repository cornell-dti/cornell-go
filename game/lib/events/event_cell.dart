import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventCell extends StatefulWidget {
  final String place;
  final String date;
  final String description;
  final bool completed;
  final bool current;
  final DateTime? time;
  final String reward;
  final int rewardNum;
  final int people;
  final String imgPath;

  EventCell(
    this.place,
    this.date,
    this.description,
    this.completed,
    this.current,
    this.time,
    this.reward,
    this.rewardNum,
    this.people,
    this.imgPath,
  );

  @override
  State<StatefulWidget> createState() => _EventCellState();
}

final defaultStyle = TextStyle(
  fontWeight: FontWeight.normal,
  fontSize: 25,
  color: Colors.white,
);

class _EventCellState extends State<EventCell> {
  final placeStyle = defaultStyle.copyWith(fontWeight: FontWeight.bold);
  final timeStyle = defaultStyle.copyWith(fontSize: 20);
  final dateStyle =
      defaultStyle.copyWith(fontSize: 15, fontStyle: FontStyle.italic);
  final descriptionStyle = defaultStyle.copyWith(fontSize: 10);
  final rewardStyle = defaultStyle.copyWith(fontSize: 15);

  bool visible = false;

  String timeToTimeString(DateTime time) {
    final diff = time.difference(DateTime.now());
    if (diff.inDays > 0) {
      return diff.inDays.toString() + " Days";
    } else if (diff.inHours > 0) {
      return diff.inHours.toString() + " Hours";
    } else if (diff.inMinutes > 0) {
      return diff.inMinutes.toString() + " Minutes";
    } else {
      return diff.inSeconds.toString() + " Seconds";
    }
  }

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
        child: Row(
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Container(
                child: Text(
                  this.widget.date,
                  style: dateStyle,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(this.widget.imgPath),
                        fit: BoxFit.cover,
                        opacity: .5,
                      ),
                    ),
                    height: 150,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                child: Text(
                                  this.widget.place,
                                  style: placeStyle,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topRight,
                                  child: (this.widget.people == -1 &&
                                          !this.widget.completed
                                      ? Container()
                                      : (this.widget.completed
                                          ? Icon(
                                              Icons.star,
                                              color: Colors.yellow,
                                              size: 25,
                                            )
                                          : Icon(
                                              Icons.people,
                                              color: Colors.white,
                                              size: 25,
                                            ))),
                                ),
                              ),
                              Container(
                                  child: Text(
                                this.widget.people < 0 || this.widget.completed
                                    ? ""
                                    : " ${this.widget.people}",
                                style: placeStyle,
                              ))
                            ],
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  width: 150,
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    this.widget.description,
                                    style: descriptionStyle,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                  child: StreamBuilder(
                                      stream:
                                          Stream.periodic(Duration(seconds: 1)),
                                      builder: (builder, value) => Text(
                                            this.widget.time == null
                                                ? ""
                                                : "${timeToTimeString(this.widget.time!)} Left",
                                            style: timeStyle,
                                          ))),
                              Expanded(
                                child: Container(
                                  child: Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          this.widget.reward,
                                          style: rewardStyle,
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          this.widget.rewardNum == 0
                                              ? ""
                                              : (this.widget.time == null
                                                  ? "∞ Rewards"
                                                  : "${this.widget.rewardNum} Reward${this.widget.rewardNum == 1 ? "" : "s"} Left"),
                                          style: rewardStyle,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: this.widget.current ? 1 : 0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.greenAccent, width: 2.0),
                      ),
                      height: 150,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
