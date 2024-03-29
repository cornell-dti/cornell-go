import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 248, 241),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 237, 86, 86),
          // Set widget before appBar title
          leading: IconButton(
            icon: const Icon(Icons.navigate_before),
            color: Colors.white,
            onPressed: () {},
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold),
          ),
          actions: [],
        ),
        body: Center(child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
              width: constraints.maxWidth * 0.9,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.only(left: 20.0),
                            alignment: Alignment.centerLeft,
                            fixedSize: Size(constraints.maxWidth, 60)),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20.0),
                              child: SvgPicture.asset(
                                'assets/icons/head.svg',
                              ),
                            ),
                            Text(
                              'Edit Profile',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.only(left: 20.0),
                            alignment: Alignment.centerLeft,
                            fixedSize: Size(constraints.maxWidth, 60)),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20.0),
                              child: SvgPicture.asset(
                                'assets/icons/bell.svg',
                              ),
                            ),
                            Text(
                              'Notifications',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.only(left: 20.0),
                            alignment: Alignment.centerLeft,
                            fixedSize: Size(constraints.maxWidth, 60)),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20.0),
                              child: SvgPicture.asset(
                                'assets/icons/feedback.svg',
                              ),
                            ),
                            Text(
                              'Feedback',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.only(left: 20.0),
                            alignment: Alignment.centerLeft,
                            fixedSize: Size(constraints.maxWidth, 60)),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20.0),
                              child: SvgPicture.asset(
                                'assets/icons/logout.svg',
                              ),
                            ),
                            Text(
                              'Logout',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    Padding(
                        padding: EdgeInsets.only(bottom: 120),
                        child: Image(
                            image: AssetImage('assets/images/go-logo.png'))),
                  ]),
            );
          },
        )));
  }
}
