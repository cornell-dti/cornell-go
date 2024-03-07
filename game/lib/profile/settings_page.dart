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
        body: Center(
          child: SizedBox(
            width: 375,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      child: ListTile(
                          leading: SvgPicture.asset(
                            'assets/icons/head.svg',
                          ),
                          title: Text(
                            'Edit Profile',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ))),
                  Divider(height: 1),
                  Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: ListTile(
                          leading: SvgPicture.asset(
                            'assets/icons/bell.svg',
                          ),
                          title: Text(
                            'Notifications',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ))),
                  Divider(height: 1),
                  Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: ListTile(
                          leading: SvgPicture.asset(
                            'assets/icons/feedback.svg',
                          ),
                          title: Text(
                            'Feedback',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ))),
                  SizedBox(height: 20),
                  Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: ListTile(
                          leading: SvgPicture.asset(
                            'assets/icons/logout.svg',
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ))),
                  Spacer(),
                  Padding(
                      padding: EdgeInsets.only(bottom: 120),
                      child: Image(
                          image: AssetImage('assets/images/go-logo.png'))),
                ]),
          ),
        ));
  }
}
