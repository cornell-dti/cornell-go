import 'package:flutter/material.dart';

Widget rewardsCell(context, title, loc, date, canRedeem, {redeemText}) {
  var imgpath = "assets/images/trophy.png";
  var titleStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black);
  var locStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 10, color: Colors.black45);
  var dateStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  var redeemStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 10, color: Colors.black);
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Row(children: [
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              date,
              style: dateStyle,
            ),
          ),
          Expanded(
              child: Column(children: [
            Container(
                color: Colors.grey,
                child: Row(
                  children: [
                    Container(
                        child: Image.asset(imgpath, height: 75, width: 75)),
                    Expanded(
                        child: Column(children: [
                      Text(
                        title,
                        style: titleStyle,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        loc,
                        style: locStyle,
                        textAlign: TextAlign.center,
                      ),
                      if (canRedeem)
                        Text("Tap to show how to redeem",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 10,
                                color: Colors.black,
                                fontStyle: FontStyle.italic))
                    ]))
                  ],
                )),
          ]))
        ]),
        if (canRedeem)
          Row(children: [
            RotatedBox(
              quarterTurns: 3,
              child: Container(
                  child: Text(
                " ",
                style: dateStyle,
              )),
            ),
            Container(
                height: 75,
                width: 342,
                color: Color.fromARGB(255, 127, 129, 129),
                child: Expanded(
                    child: FittedBox(
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(redeemText, style: redeemStyle)))))
          ])
      ]));
}
