import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:game/api/game_api.dart';
import 'package:game/challenges/challenges_widget.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/login/login_page.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/reward_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:game/widget/game_widget.dart';
import 'package:provider/provider.dart';

import 'dart:io' show Platform;

import 'challenges/challenges_page.dart';
import 'gameplay/gameplay_map.dart';

const ENV_URL = String.fromEnvironment('API_URL', defaultValue: "");

final storage = FlutterSecureStorage();
final LOOPBACK =
    (Platform.isAndroid ? "http://10.0.2.2:8080" : "http://0.0.0.0:8080");
final API_URL = ENV_URL == "" ? LOOPBACK : ENV_URL;

void main() {
  print(API_URL);
  runApp(MyApp());
}

final client = ApiClient(storage, API_URL);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: client),
          ChangeNotifierProvider(
            create: (_) => UserModel(client),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => RewardModel(client),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => GroupModel(client),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => EventModel(client),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => TrackerModel(client),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => ChallengeModel(client),
            lazy: false,
          )
        ],
        child: GameWidget(
            child: MaterialApp(
          title: 'CornellGO!',
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          theme: ThemeData(primarySwatch: Colors.blue),
          home: GameplayPage(),
        )));
  }
}
