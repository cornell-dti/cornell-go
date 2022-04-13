import 'package:flutter/material.dart';

Widget rewardsCell(context, title, loc, date, canRedeem, [redeemText]) {
  var imgpath = "assets/images/trophy.png";
  var titleStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black);
  var locStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 10, color: Colors.grey);
  var dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  var redeemStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 20, color: Colors.black);
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        RotatedBox(
          quarterTurns: 3,
          child: Container(
              child: Text(
            date,
            style: dateStyle,
          )),
        ),
        Expanded(
            child: Column(children: [
          Container(
              child: Row(
            children: [
              Container(child: Image.asset(imgpath)),
              Column(children: [
                Text(title, style: titleStyle),
                Text(loc, style: locStyle),
                if (canRedeem)
                  Text("Tap to show how to redeem",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 25,
                          color: Colors.black,
                          fontStyle: FontStyle.italic))
              ])
            ],
          )),
          if (canRedeem) Container(child: Text(redeemText, style: redeemStyle))
        ]))
      ]));
}
