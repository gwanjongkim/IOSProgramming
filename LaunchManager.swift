//
//  ㅣ며ㅜ초ㅡ뭄ㅎㄷㄱ.swift
//  TravelGuide
//
//  Created by 관중 mac on 6/6/25.
//

import Foundation
import FirebaseAuth

final class LaunchManager {
    static let shared = LaunchManager()

    private init() {}

    func configureInitialAuthState() {
        if Auth.auth().currentUser == nil {
            // 최초 실행 시 익명 로그인
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ 익명 로그인 실패:", error)
                } else {
                    print("✅ 익명 로그인 성공: \(result?.user.uid ?? "")")
                }
            }
        } else {
            print("🔐 기존 사용자 로그인 상태 유지: \(Auth.auth().currentUser?.uid ?? "")")
        }
    }
}
