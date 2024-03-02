import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_config/flutter_config.dart';

// imports for google maps
import 'dart:io' show Platform;
import 'dart:async';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// api and widget imports
import 'package:game/api/game_api.dart';
import 'package:game/challenges/challenges_widget.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/gameplay/gameplay_map.dart';
import 'package:game/global_leaderboard/global_leaderboard_widget.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/login/login_page.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:game/home_page/home_page_widget.dart';
import 'package:game/widget/game_widget.dart';
import 'package:provider/provider.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/color_palette.dart';

const ENV_URL = String.fromEnvironment('API_URL', defaultValue: "");

final storage = FlutterSecureStorage();
final LOOPBACK =
    (Platform.isAndroid ? "http://10.0.2.2:8080" : "http://0.0.0.0:8080");
final API_URL = ENV_URL == "" ? LOOPBACK : ENV_URL;

void main() async {
  print(API_URL);
  final GoogleMapsFlutterPlatform platform = GoogleMapsFlutterPlatform.instance;
  // should only apply to Android - needs to be tested for iOS
  (platform as GoogleMapsFlutterAndroid).useAndroidViewSurface = true;
  initializeMapRenderer();
  // load environment variables
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  await FlutterConfig.loadEnvVariables();

  runApp(MyApp());
}

Completer<AndroidMapRenderer?>? _initializedRendererCompleter;

/// Initializes map renderer to the `latest` renderer type.
///
/// The renderer must be requested before creating GoogleMap instances,
/// as the renderer can be initialized only once per application context.
Future<AndroidMapRenderer?> initializeMapRenderer() async {
  if (_initializedRendererCompleter != null) {
    return _initializedRendererCompleter!.future;
  }

  final Completer<AndroidMapRenderer?> completer =
      Completer<AndroidMapRenderer?>();
  _initializedRendererCompleter = completer;

  WidgetsFlutterBinding.ensureInitialized();

  final GoogleMapsFlutterPlatform platform = GoogleMapsFlutterPlatform.instance;
  unawaited((platform as GoogleMapsFlutterAndroid)
      .initializeWithRenderer(AndroidMapRenderer.latest)
      .then((AndroidMapRenderer initializedRenderer) =>
          completer.complete(initializedRenderer)));

  return completer.future;
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
          theme: ThemeData(
              fontFamily: 'Poppins', primarySwatch: ColorPalette.BigRed),
          // home: SplashPageWidget(),
          // home: HomePageWidget(),
          home: GameplayMap(),
        )));
  }
}
