//
//  AppDelegate.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/30/25.
//
import UIKit
import FirebaseCore
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// 리스너 핸들을 보관했다가 필요하면 제거
    private var authHandle: AuthStateDidChangeListenerHandle?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1️⃣ Firebase 초기화
        FirebaseApp.configure()

        // 2️⃣ 익명 로그인(필요 시)
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error { print("🛑 Auth error:", error) }
                else { print("✅ Signed-in uid:", result?.user.uid ?? "") }
            }
        }

        // 3️⃣ 리스너 등록 -> Notification 포스트
        authHandle = Auth.auth().addStateDidChangeListener { _, user in
            NotificationCenter.default.post(
                name: .authStateChanged,
                object: user             // user == nil ➜ 로그아웃
            )
        }

        return true
    }

    // 필요하다면 앱 종료 직전 리스너 제거
    func applicationWillTerminate(_ application: UIApplication) {
        if let h = authHandle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }

    // MARK: UISceneSession Lifecycle (변경 없음)
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}

extension Notification.Name {
    static let authStateChanged = Notification.Name("AuthStateChanged")
}
