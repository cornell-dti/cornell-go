import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/** ChallengeCell is deprecated and can be removed. */
class ChallengeCell extends StatefulWidget {
  final String place;
  final String description;
  final String imageUrl;
  final bool isVisited;

  ChallengeCell(this.place, this.description, this.imageUrl, this.isVisited);

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
              Image(image: NetworkImage(this.widget.imageUrl)),
              Column(
                children: [
                  Text(this.widget.place),
                  Text(this.widget.description),
                ],
              )
            ])));
  }
}
