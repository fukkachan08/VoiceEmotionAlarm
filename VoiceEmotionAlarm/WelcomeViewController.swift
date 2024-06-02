import UIKit
import SwiftUI

class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        print("WelcomeViewController viewDidLoad")

        let label = UILabel()
        label.text = "アプリの概要"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let startButton = UIButton(type: .system)
        startButton.setTitle("はじめる", for: .normal)
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20)
        ])
        
        // デバッグ用にビューの色を設定
        view.backgroundColor = .red
        label.backgroundColor = .yellow
        startButton.backgroundColor = .green
    }

    @objc func startButtonTapped() {
        print("startButtonTapped")
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true, completion: nil)
    }
}

