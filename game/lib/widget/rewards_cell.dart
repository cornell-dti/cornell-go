import 'package:flutter/material.dart';

class AnimatedRewardCell extends StatefulWidget {
  final String _title;
  final String _eventName;
  final String? _redeemText;

  const AnimatedRewardCell(String title, String eventName, String redeemText,
      {Key? key})
      : _title = title,
        _eventName = eventName,
        _redeemText = redeemText == "" ? null : redeemText,
        super(key: key);

  @override
  _AnimatedRewardCellState createState() =>
      _AnimatedRewardCellState(_title, _eventName, _redeemText);
}

class _AnimatedRewardCellState extends State<AnimatedRewardCell> {
  final String _title;
  final String _eventName;
  final String? _redeemText;

  bool expanded = false;

  _AnimatedRewardCellState(String title, String eventName, String? redeemText)
      : _title = title,
        _eventName = eventName,
        _redeemText = redeemText;

  @override
  Widget build(BuildContext context) {
    final imgpath = "assets/images/trophy.png";
    final titleStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black);
    final locStyle = TextStyle(
        fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black45);
    final redeemStyle = TextStyle(
        fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Column(children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                child: Container(
                    color: Colors.grey,
                    child: Row(
                      children: [
                        Container(
                            child: Image.asset(imgpath, height: 75, width: 75)),
                        Expanded(
                            child: Column(children: [
                          Text(
                            _title,
                            style: titleStyle,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _eventName,
                            style: locStyle,
                            textAlign: TextAlign.center,
                          ),
                          if (_redeemText != null)
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
              )
            ])),
          ]),
          if (_redeemText != null)
            Row(children: [
              Expanded(
                  child: AnimatedContainer(
                      height: expanded ? 75 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.fastOutSlowIn,
                      color: Color.fromARGB(255, 127, 129, 129),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(_redeemText!, style: redeemStyle)))))
            ])
        ]));
  }
}
