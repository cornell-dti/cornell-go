import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/events_leaderboard/events_leaderboard_widget.dart';
import 'package:game/feedback/feedback.dart';
import 'package:game/events_leaderboard/events_leaderboard_widget.dart';
import 'package:game/global_leaderboard/global_leaderboard_widget.dart';
import 'package:game/login/login_page.dart';
import 'package:game/model/user_model.dart';
import 'package:game/rewards/rewards_widget.dart';
import 'package:game/visited_places/visited_places_widget.dart';
import 'package:game/challenges/challenges_widget.dart';
import 'package:game/events/events_widget.dart';
import 'package:game/username/username_widget.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:url_launcher/url_launcher.dart';

const androidForm =
    "https://docs.google.com/forms/d/e/1FAIpQLScpffXZMHHfvY9zD_11wqrEaZTEy3dVD3OZz4iugzBKTEKQtw/viewform";
const iosForm =
    "https://docs.google.com/forms/d/e/1FAIpQLSdE3Hrt9OXvYEakj0n0wHuUUd_D_LGRpx_YkvA7-D_05ybGSw/viewform";

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const listTextStyle =
        TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);
    return Drawer(child: Consumer2<UserModel, ApiClient>(
        builder: (context, userModel, apiClient, child) {
      return Container(
        decoration: BoxDecoration(color: Colors.black87),
        child: ListView(
          // Remove padding
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Hi, " + (userModel.userData?.username ?? ""),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              accountEmail: Text(
                '',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 0),
              ),
              currentAccountPicture: CircleAvatar(
                child: ClipOval(
                  child: Container(
                    decoration: BoxDecoration(
                        color: constructColorFromUserName(
                            userModel.userData?.username ?? "")),
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                  color: RGBComplement(constructColorFromUserName(
                      userModel.userData?.username ?? ""))),
            ),
            ListTile(
                leading: Icon(
                  Icons.event,
                  color: Color(0xFFB31B1B),
                ),
                title: Text('Events', style: listTextStyle),
                onTap: () => {
                      Navigator.pop(context),
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EventsWidget()))
                    }),
            ListTile(
                leading: Icon(
                  Icons.star,
                  color: Color(0xFFB31B1B),
                ),
                title: Text('Challenges', style: listTextStyle),
                onTap: () => {
                      Navigator.pop(context),
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChallengesWidget()))
                    }),
            ListTile(
                leading: Icon(
                  Icons.emoji_events,
                  color: Color(0xFFB31B1B),
                ),
                title: Text('Rewards', style: listTextStyle),
                onTap: () => {
                      Navigator.pop(context),
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RewardsWidget()))
                    }),
            ListTile(
              leading: Icon(
                Icons.group_rounded,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Event Leaderboard', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EventsLeaderboardWidget()))
              },
            ),
            ListTile(
              leading: Icon(
                Icons.leaderboard,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Global Leaderboard', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GlobalLeaderboardWidget()))
              },
            ),
            ListTile(
              leading: Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Feedback', style: listTextStyle),
              onTap: () async {
                if (Platform.isAndroid) {
                  await launch(androidForm,
                      forceWebView: true, enableJavaScript: true);
                } else if (Platform.isIOS) {
                  await launch(iosForm, forceSafariVC: true);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Change Username', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserNameWidget()))
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Color(0xFFB31B1B)),
              title: Text('Sign Out', style: listTextStyle),
              onTap: () async => {
                await apiClient.disconnect(),
                Navigator.pop(context),
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginWidget()))
              },
            )
          ],
        ),
      );
    }));
  }
}
