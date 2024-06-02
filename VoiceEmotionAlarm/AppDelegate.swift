import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("AppDelegate didFinishLaunchingWithOptions")

        window = UIWindow(frame: UIScreen.main.bounds)
        let welcomeViewController = WelcomeViewController()
        window?.rootViewController = welcomeViewController
        window?.makeKeyAndVisible()

        return true
    }
}

