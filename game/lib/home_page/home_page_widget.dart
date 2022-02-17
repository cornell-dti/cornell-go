import 'dart:ffi';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:game/Widgets/nav_bar.dart';
import 'package:game/Widgets/nav_btn.dart';

class HomePageWidget extends StatefulWidget {
  HomePageWidget({Key? key}) : super(key: key);
  var scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  TextEditingController textController = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Color Carnelian = Color(0xFFB31B1B);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = const BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    return Scaffold(
        floatingActionButton: navBtn(scaffoldKey),
        drawer: NavBar(),
        key: scaffoldKey,
        backgroundColor: const Color(0xFFFFFF),
        body: Stack(children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/main-bg.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SlidingUpPanel(
              minHeight: 200,
              padding: const EdgeInsets.all(8),
              backdropEnabled: true,
              backdropTapClosesPanel: true,
              borderRadius: radius,
              parallaxEnabled: true,
              color: Colors.black87,
              header: Container(
                width: MediaQuery.of(context).size.width,
                height: 3.5,
                alignment: Alignment.center,
                child: Container(
                    width: 70,
                    height: 3.5,
                    decoration: new BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    )),
              ),
              panel: _panel()),
        ]));
  }

  Widget _panel() {
    return VStack([
      Row(
        children: [
          Padding(
              padding: EdgeInsets.all(6),
              child: HStack([
                Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.bolt, color: Carnelian)),
                Padding(
                  padding: EdgeInsets.all(3),
                  child: Text("3 Points",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ])),
          Padding(
              padding: EdgeInsets.all(6),
              child: HStack([
                Padding(
                    padding: EdgeInsets.all(3),
                    child:
                        Icon(Icons.follow_the_signs_rounded, color: Carnelian)),
                Padding(
                  padding: EdgeInsets.all(3),
                  child: Text("20 mins",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ])),
          Padding(
              padding: EdgeInsets.all(6),
              child: HStack([
                Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.group_add_rounded,
                        color: Color(0xFFB31B1B))),
                Padding(
                  padding: EdgeInsets.all(3),
                  child: Text("4/8 ready",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ]))
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
      Container(
        margin: new EdgeInsets.symmetric(vertical: 0),
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: const Text(
            "One of the most recognizable landmarks of Cornell, this tower can be heard and found above a library.",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
      Container(
        margin: new EdgeInsets.symmetric(vertical: 20),
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.center,
        child: VStack([
          Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: 40,
              decoration: new BoxDecoration(
                  color: Colors.white,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.blue,
                      Colors.red,
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(32))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "Far",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      "Close",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ))
        ]),
      ),
      Container(
        alignment: Alignment.center,
        child: Row(
          children: [
            const Text(
              "Group ABCD (8/8)",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () => {print("Join-Group pressed")},
              child: const Text(
                "Join!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                  backgroundColor: Carnelian,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)))),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
      ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        children: [
          _listCell("Your username", "5 points", true),
          _listCell("Your friend #1", "4 points", false),
          _listCell("Your friend #2", "3 points", false)
        ],
      )
    ]);
  }

  Widget _listCell(String name, String points, bool isUser) {
    String btnTxt = (isUser) ? "Disband" : "Leave";
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 5,
                child: Row(
                  children: [
                    Icon(Icons.check_box_rounded, color: Colors.grey),
                    Icon(Icons.camera_alt_rounded, color: Carnelian)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: Carnelian, fontWeight: FontWeight.bold)),
                  Text(
                    points,
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  )
                ],
              )
            ],
          ),
          Container(
              width: MediaQuery.of(context).size.width / 4,
              child: ElevatedButton(
                onPressed: () => {print("Disband-pressed")},
                child: Text(
                  btnTxt,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                    backgroundColor: Carnelian,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)))),
              ))
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }
}
