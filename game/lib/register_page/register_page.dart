import 'package:flutter/material.dart';
import 'package:game/details_page/details_page.dart';
import 'package:game/widget/lato_text.dart';

class RegisterPageWidget extends StatefulWidget {
  RegisterPageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _RegisterPageWidgetState createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  String _selectedOption = "";

  @override
  void initState() {
    super.initState();
    _selectedOption = "Graduate Student";
  }

  final List<String> identityOptions = [
    "Undergraduate Student",
    "Graduate Student",
    "Faculty/Staff",
    "Alumni"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  LatoText("Who are you", 24, Colors.black, FontWeight.w700)
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              Column(
                  children: identityOptions.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: entry == _selectedOption
                              ? MaterialStatePropertyAll<Color>(Colors.black)
                              : MaterialStatePropertyAll<Color>(Colors.white)),
                      onPressed: () => {
                            setState(() {
                              _selectedOption = entry;
                            })
                          },
                      child: Container(
                        width: 255,
                        height: 53,
                        child: Align(
                          alignment: Alignment.center,
                          child: LatoText(
                              entry,
                              16.0,
                              entry != _selectedOption
                                  ? Colors.black
                                  : Colors.white,
                              FontWeight.w600),
                        ),
                      )),
                );
              }).toList()),
              SizedBox(
                height: 100,
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll<Color>(Colors.black)),
                child: Container(
                    width: 255,
                    height: 53,
                    child: Align(
                      alignment: Alignment.center,
                      child: LatoText(
                          "Continue", 16.0, Colors.white, FontWeight.w600),
                    )),
                onPressed: () => {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DetailsPageWidget(
                        userType: _selectedOption,
                      ),
                    ),
                  )
                },
              ),
            ]),
      ),
    );
  }
}
