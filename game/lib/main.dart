import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:game/api/game_api.dart';
import 'package:game/home_page/home_page_widget.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/reward_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

final storage = FlutterSecureStorage();
final LOOPBACK = (Platform.isAndroid ? "10.0.2.2" : "127.0.0.1");
final API_URL = String.fromEnvironment('API_URL', defaultValue: LOOPBACK);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'game',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChangeNotifierProvider(
        create: (_) => ApiClient(storage, API_URL),
        child: Consumer<ApiClient>(
            builder: (_, client, home) => MultiProvider(providers: [
                  ChangeNotifierProvider(create: (_) => UserModel(client)),
                  ChangeNotifierProvider(create: (_) => RewardModel(client)),
                  ChangeNotifierProvider(create: (_) => GroupModel(client)),
                  ChangeNotifierProvider(create: (_) => EventModel(client)),
                  ChangeNotifierProvider(create: (_) => TrackerModel(client)),
                  ChangeNotifierProvider(create: (_) => ChallengeModel(client)),
                  Provider(create: (_) => client)
                ], child: home),
            child: HomePageWidget()),
      ),
    );
  }
}
