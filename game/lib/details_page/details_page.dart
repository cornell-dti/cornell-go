import 'package:flutter/material.dart';
import 'package:game/widget/lato_text.dart';

class DetailsPageWidget extends StatefulWidget {
  DetailsPageWidget({Key? key, required String userType}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _DetailsPageWidgetState createState() => _DetailsPageWidgetState();
}

class _DetailsPageWidgetState extends State<DetailsPageWidget> {
  String _year = "2025";
  String _username = "";
  String _name = "";
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  List<String> _years = ["2025"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 50),
          child:
              // Build a Form widget using the _formKey created above.
              Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LatoText("Name", 18, Colors.black, FontWeight.w700),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'e.g. Jane Doe',
                      ),
                      onSaved: (newValue) => setState(() {
                        _name = newValue!;
                      }),
                      // The validator receives the text that the user has entered.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LatoText("Username", 18, Colors.black, FontWeight.w700),
                    SizedBox(height: 10),
                    TextFormField(
                      onSaved: (newValue) => setState(() {
                        _username = newValue!;
                      }),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'e.g. JaneDoe123',
                      ),

                      // The validator receives the text that the user has entered.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LatoText("Graduation Year (optional)", 18, Colors.black,
                        FontWeight.w700),
                    SizedBox(height: 10),
                    DropdownButton(
                      value: _year,
                      onChanged: (newValue) {
                        print(newValue);
                        setState(() {
                          _year = newValue.toString();
                        });
                      },
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          child: Container(
                              width: 255,
                              height: 53,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: LatoText(
                                    year, 16.0, Colors.black, FontWeight.w600),
                              )),
                          value: year,
                        );
                      }).toList(),
                    )
                  ],
                ),
                ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing Data')),
                        );
                      }
                    },
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
                  ),
              ],
            ),
          )),
    );
  }
}
