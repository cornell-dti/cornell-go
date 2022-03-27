import 'package:flutter/material.dart';
import 'package:game/feedback/feedback.dart';
import 'package:game/leaderboard/leaderboard_widget.dart';
import 'package:game/login/login_page.dart';
import 'package:game/model/user_model.dart';
import 'package:game/visited_places/visited_places_widget.dart';
import 'package:game/username/username_widget.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/utils/utility_functions.dart';

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
                Icons.text_fields,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Change username', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserNameWidget()))
              },
            ),
            ListTile(
              leading: Icon(
                Icons.group_rounded,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Leaderboard', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LeaderboardWidget()))
              },
            ),
            ListTile(
                leading: Icon(
                  Icons.location_history_rounded,
                  color: Color(0xFFB31B1B),
                ),
                title: Text('Visited places', style: listTextStyle),
                onTap: () => {
                      Navigator.pop(context),
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VisitedPlacesWidget()))
                    }),
            ListTile(
              leading: Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Feedback', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => FeedbackWidget()))
              },
            ),
            ListTile(
              leading: Icon(Icons.time_to_leave, color: Color(0xFFB31B1B)),
              title: Text('Sign Out', style: listTextStyle),
              onTap: () => {
                apiClient.disconnect(),
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
