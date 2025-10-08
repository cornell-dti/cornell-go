import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/profile/edit_profile.dart';
import 'package:game/main.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

final SUPPORT_URL =
    Uri.parse("https://sites.google.com/cornell.edu/cornellgosupport");

class SettingsPage extends StatelessWidget {
  final bool isGuest;
  const SettingsPage(this.isGuest, {super.key});

  @override
  Widget build(BuildContext context) {
    var headerStyle = TextStyle(
      color: Color(0xFFFFF8F1),
      fontSize: 20,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 248, 241),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 237, 86, 86),
          toolbarHeight: MediaQuery.of(context).size.height * 0.08,
          leading: Align(
            alignment: Alignment.center,
            child: IconButton(
              icon: Icon(Icons.navigate_before),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
            child: Text(
              'Settings',
              style: headerStyle,
            ),
          ),
          centerTitle: true, // Still useful for horizontal centering
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
                    if (!isGuest)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            topLeft: Radius.circular(10),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditProfileWidget()));
                          },
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
                    if (!isGuest) Divider(height: 1),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          launchUrl(SUPPORT_URL);
                        },
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
                              'Support',
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
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          displayTextInputDialog(
                              context, "Join Organization", "Access Code",
                              (text) {
                            client.serverApi?.joinOrganization(
                                JoinOrganizationDto(
                                    accessCode: text.toLowerCase()));
                          });
                        },
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
                              'Join Organization',
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
                          bottomRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          await client.disconnect();
                        },
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
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          showDeletionConfirmationAlert(context, client);
                        },
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.only(left: 20.0),
                            alignment: Alignment.centerLeft,
                            fixedSize: Size(constraints.maxWidth, 60)),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20.0),
                              child: SvgPicture.asset(
                                'assets/icons/delete.svg',
                                width: 14,
                                height: 14,
                              ),
                            ),
                            Text(
                              'Delete Account',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.red),
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
