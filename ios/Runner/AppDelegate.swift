import Flutter
import UIKit

// Google Maps API key — used by navigation deep links and future Maps SDK integration.
let kGoogleMapsApiKey = "AIzaSyAFE6uAxBve7ttuXg7CjjN_FOfB8V13a10"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
