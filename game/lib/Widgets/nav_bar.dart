import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
                CupertinoIcons.group,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Leaderboard', style: listTextStyle),
              onTap: () => null,
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.arrow_2_circlepath_circle,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Visisted places', style: listTextStyle),
              onTap: () => null,
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.lightbulb,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Suggest Location', style: listTextStyle),
              onTap: () => null,
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.text_bubble,
                color: Color(0xFFB31B1B),
              ),
              title: Text('Give feedback', style: listTextStyle),
              onTap: () => null,
            ),
            ListTile(
              leading: Icon(CupertinoIcons.settings, color: Color(0xFFB31B1B)),
              title: Text('Settings', style: listTextStyle),
              onTap: () => null,
            )
          ],
        ),
      ),
    );
  }
}
