import UIKit
import Flutter
import Firebase
import GoogleMaps
import flutter_config

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FirebaseApp.configure()
    GMSServices.provideAPIKey(FlutterConfigPlugin.env(for: "IOS_MAP_API_KEY"))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
