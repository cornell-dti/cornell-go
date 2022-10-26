import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final defaultStyle = TextStyle(
      fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black);
  @override
  Widget build(BuildContext context) {
    final titleStyle =
        defaultStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16);
    final locStyle = defaultStyle.copyWith(color: Colors.black45);
    final redeemStyle = defaultStyle.copyWith(fontSize: 20);
    final redeemLinkStyle = defaultStyle.copyWith(color: Colors.black);
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
                            child: Icon(
                          Icons.emoji_events,
                          color: Color(0xFFE6D23E),
                          size: 75,
                        )),
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
                                style: defaultStyle.copyWith(
                                    fontSize: 16, fontStyle: FontStyle.italic))
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
                              child: Linkify(
                                  onOpen: (link) async => await launch(link.url,
                                      forceWebView: true,
                                      enableJavaScript: true,
                                      forceSafariVC: true),
                                  style: redeemStyle,
                                  text: _redeemText!,
                                  linkStyle: redeemLinkStyle)))))
            ])
        ]));
  }
}
