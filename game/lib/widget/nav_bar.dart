// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:game/events_leaderboard/events_leaderboard_widget.dart';
// import 'package:game/global_leaderboard/global_leaderboard_widget.dart';
// import 'package:game/login/login_page.dart';
// import 'package:game/model/user_model.dart';
// import 'package:game/rewards/rewards_widget.dart';
// import 'package:game/challenges/challenges_widget.dart';
// import 'package:game/events/events_widget.dart';
// import 'package:game/username/username_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:game/api/game_api.dart';
// import 'package:game/utils/utility_functions.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:game/feedback/feedback.dart';
// import 'nav_widget.dart';

// const androidForm =
//     "https://docs.google.com/forms/d/e/1FAIpQLScpffXZMHHfvY9zD_11wqrEaZTEy3dVD3OZz4iugzBKTEKQtw/viewform";
// const iosForm =
//     "https://docs.google.com/forms/d/e/1FAIpQLSdE3Hrt9OXvYEakj0n0wHuUUd_D_LGRpx_YkvA7-D_05ybGSw/viewform";

// class NavBar extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     const listTextStyle =
//         TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);
//     Color Carnelian = Color(0xFFB31B1B);

//     return Drawer(child: Consumer2<UserModel, ApiClient>(
//         builder: (context, userModel, apiClient, child) {
//       return Container(
//         decoration: BoxDecoration(color: Colors.black87),
//         child: ListView(
//           // Remove padding
//           padding: EdgeInsets.zero,
//           children: [
//             UserAccountsDrawerHeader(
//               accountName: Text("Hi, " + (userModel.userData?.username ?? ""),
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 20)),
//               accountEmail: Text(
//                 '',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 0),
//               ),
//               currentAccountPicture: CircleAvatar(
//                 child: ClipOval(
//                   child: Container(
//                     decoration: BoxDecoration(
//                         color: constructColorFromUserName(
//                             userModel.userData?.username ?? "")),
//                     width: 90,
//                     height: 90,
//                   ),
//                 ),
//               ),
//               decoration: BoxDecoration(
//                   color: RGBComplement(constructColorFromUserName(
//                       userModel.userData?.username ?? ""))),
//             ),
//             navTab(context, Icons.event, 'Events', EventsWidget()),
//             navTab(context, Icons.star, 'Challenges', ChallengesWidget()),
//             navTab(context, Icons.emoji_events, 'Events', RewardsWidget()),
//             navTab(context, Icons.group_rounded, 'Event Leaderboard',
//                 EventsLeaderboardWidget()),
//             navTab(context, Icons.leaderboard, 'Global Leaderboard',
//                 GlobalLeaderboardWidget()),
//             ListTile(
//               leading: Icon(
//                 Icons.chat_bubble_rounded,
//                 color: Carnelian,
//               ),
//               title: Text('Feedback', style: listTextStyle),
//               onTap: () async {
//                 if (Platform.isAndroid) {
//                   await launch(androidForm,
//                       forceWebView: true, enableJavaScript: true);
//                 } else if (Platform.isIOS) {
//                   await launch(iosForm, forceSafariVC: true);
//                 }
//               },
//             ),
//             navTab(context, Icons.edit, 'Change Username', UserNameWidget()),
//             ListTile(
//               leading: Icon(Icons.exit_to_app, color: Carnelian),
//               title: Text('Sign Out', style: listTextStyle),
//               onTap: () async => {
//                 await apiClient.disconnect(),
//                 Navigator.pop(context),
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => LoginWidget()))
//               },
//             )
//           ],
//         ),
//       );
//     }));
//   }
// }
