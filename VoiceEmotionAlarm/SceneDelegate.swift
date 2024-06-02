import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        print("SceneDelegate scene:willConnectTo")
        let window = UIWindow(windowScene: windowScene)
        let welcomeViewController = WelcomeViewController()
        window.rootViewController = welcomeViewController
        self.window = window
        window.makeKeyAndVisible()
    }
}

