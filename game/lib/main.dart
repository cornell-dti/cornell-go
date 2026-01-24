import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_config_plus/flutter_config_plus.dart';
import 'package:device_preview/device_preview.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/loading_page/loading_page.dart';
import 'package:game/model/achievement_model.dart';
import 'package:device_preview/device_preview.dart';
import 'package:game/model/onboarding_model.dart';
import 'package:game/model/timer_model.dart';

// imports for google maps
import 'dart:io' show Platform;
import 'dart:async';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// api and widget imports
import 'package:game/api/game_api.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:game/widget/game_widget.dart';
import 'package:provider/provider.dart';
import 'package:game/color_palette.dart';

const bool USE_DEVICE_PREVIEW = false;
final storage = FlutterSecureStorage();
late final String API_URL;
late final ApiClient client;

void main() async {
  // Initialize Flutter bindings first - required for ALL plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await FlutterConfigPlus.loadEnvVariables();

  // Define LOOPBACK and get API_URL from dart-define OR .env file
  final localServerURL =
      (Platform.isAndroid ? "http://10.0.2.2:8080" : "http://localhost:8080");

  // First try dart-define (for production builds), then .env file (for development), then fallback to loopback
  API_URL = const String.fromEnvironment('API_URL', defaultValue: '').isEmpty
      ? (FlutterConfigPlus.get('API_URL') ?? localServerURL)
      : const String.fromEnvironment('API_URL');

  print('Using API URL: $API_URL');

  // Initialize API client
  client = ApiClient(storage, API_URL);

  // Init Google Maps platform
  final GoogleMapsFlutterPlatform platform = GoogleMapsFlutterPlatform.instance;
  // should only apply to Android - needs to be tested for iOS
  if (platform is GoogleMapsFlutterAndroid) {
    (platform).useAndroidViewSurface = true;
    initializeMapRenderer();
  }

  // Set preferred orientations to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    USE_DEVICE_PREVIEW
        ? DevicePreview(
            enabled: !kReleaseMode,
            builder: (context) => MyApp(),
          )
        : MyApp(),
  );
}

Completer<AndroidMapRenderer?>? _initializedRendererCompleter;

/// Initializes map renderer to the `latest` renderer type.
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
  unawaited(
    (platform as GoogleMapsFlutterAndroid)
        .initializeWithRenderer(AndroidMapRenderer.latest)
        .then(
          (AndroidMapRenderer initializedRenderer) =>
              completer.complete(initializedRenderer),
        ),
  );
  return completer.future;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: client),
        ChangeNotifierProvider(create: (_) => UserModel(client), lazy: false),
        ChangeNotifierProvider(
            create: (_) => OnboardingModel(client), lazy: false),
        ChangeNotifierProvider(create: (_) => GroupModel(client), lazy: false),
        ChangeNotifierProvider(create: (_) => EventModel(client), lazy: false),
        ChangeNotifierProvider(
          create: (_) => AchievementModel(client),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => TrackerModel(client),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => ChallengeModel(client),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => TimerModel(client),
          lazy: false,
        ),
      ],
      child: GameWidget(
        child: MaterialApp(
          useInheritedMediaQuery: USE_DEVICE_PREVIEW,
          locale: USE_DEVICE_PREVIEW ? DevicePreview.locale(context) : null,
          builder: USE_DEVICE_PREVIEW ? DevicePreview.appBuilder : null,
          title: 'CornellGO!',
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          theme: ThemeData(
            fontFamily: 'Poppins',
            primarySwatch: ColorPalette.BigRed,
            useMaterial3: false,
          ),
          home: LoadingPageWidget(client.tryRelog()),
        ),
      ),
    );
  }
}
