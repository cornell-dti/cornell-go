import 'package:flutter/material.dart';
import 'package:game/feedback/feedback.dart';
import 'package:game/leaderboard/leaderboard_widget.dart';
import 'package:game/settings/settings.dart';
import 'package:game/suggestions/suggestions.dart';
import 'package:game/visited_places/visited_places_widget.dart';

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const listTextStyle =
        TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);
    return Drawer(
      child: Container(
        decoration: BoxDecoration(color: Colors.black87),
        child: ListView(
          // Remove padding
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                'test',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                'test@cornell.edu',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: CircleAvatar(
                child: ClipOval(
                  child: Image.network(
                    'https://www.w3schools.com/howto/img_avatar.png',
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: NetworkImage(
                        'https://vistapointe.net/images/cornell-university-wallpaper-14.jpg')),
              ),
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
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Suggest Location', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SuggestionsWidget()))
              },
            ),
            ListTile(
              leading: Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Give feedback', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => FeedbackWidget()))
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_rounded, color: Color(0xFFB31B1B)),
              title: Text('Settings', style: listTextStyle),
              onTap: () => {
                Navigator.pop(context),
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsWidget()))
              },
            )
          ],
        ),
      ),
    );
  }
}
