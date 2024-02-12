import 'package:flutter/material.dart';

/**
 * The profile page of the app that is rendered for the user's profile
 */
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      children: [
        SizedBox(
          height: 60,
        ),
        Image(image: AssetImage("assets/images/user_2@2x.png")),
        Text("246 points"),
        Text("Hanan Abraha"),
        Text("@Hanan Abraha"),
        Text("Achievements",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        Text("Completed",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
      ],
    )));
  }
}
