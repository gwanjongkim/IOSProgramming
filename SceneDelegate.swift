    //
    //  SceneDelegate.swift
    //  TravelGuide
    //
    //  Created by 관중 mac on 5/30/25.
    //

import UIKit
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let locationManager = CLLocationManager()
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        print("✅ SceneDelegate.willConnect")        // ← 반드시 찍히는지 확인
        locationManager.requestWhenInUseAuthorization()
        guard let winScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: winScene)
        self.window = window

        // 첫 화면 = AppTabBarController
        window.rootViewController = AppTabBarController()
        window.makeKeyAndVisible()

        // (선택) Firebase 익명 로그인
        AuthManager.shared.signInIfNeeded()
        
    }
}
