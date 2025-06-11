//
//  AuthManager.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

final class AuthManager: NSObject {
    static let shared = AuthManager()
    private override init() { super.init() }

    // MARK: — 사용자 정보
    var uid: String? {
        Auth.auth().currentUser?.uid
    }
    var isAnonymous: Bool {
        Auth.auth().currentUser?.isAnonymous ?? false
    }
    var userEmail: String? {
        Auth.auth().currentUser?.email
    }
    var userName: String? {
        Auth.auth().currentUser?.displayName
    }

    // MARK: — 익명 로그인
    func signInIfNeeded() {
        guard Auth.auth().currentUser == nil else { return }
        Auth.auth().signInAnonymously { res, err in
            if let e = err { print("🛑 익명 로그인 오류:", e) }
            else { print("✅ 익명 로그인 됨, uid:", res?.user.uid ?? "") }
        }
    }

    // MARK: — 로그아웃 (익명 재생성 없음)
    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: — Sign in with Apple
    private var currentNonce: String?

    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let ctrl = ASAuthorizationController(authorizationRequests: [request])
        ctrl.delegate = self
        ctrl.presentationContextProvider = self
        ctrl.performRequests()
    }

    // MARK: — Helpers
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
    private func randomNonceString(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        var str = "", remaining = length
        while remaining > 0 {
            let rnd = UInt8.random(in: 0..<UInt8(chars.count))
            str.append(chars[Int(rnd)]); remaining -= 1
        }
        return str
    }
}

// MARK: — ASAuthorizationControllerDelegate
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleIDCred = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = appleIDCred.identityToken,
            let idToken  = String(data: tokenData, encoding: .utf8)
        else { return }

        // Firebase용 크리덴셜 생성 (fullName 파라미터도 제공 가능)
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idToken,
            rawNonce: nonce
        )

        Auth.auth().signIn(with: credential) { result, error in
            if let err = error {
                print("🛑 Apple 로그인 오류:", err)
                return
            }
            // 로그인 성공
            if let user = result?.user,
               let givenName = appleIDCred.fullName?.givenName {
                let changeReq = user.createProfileChangeRequest()
                changeReq.displayName = givenName
                changeReq.commitChanges { err in
                    if let e = err {
                        print("프로필 이름 설정 오류:", e)
                    } else {
                        print("프로필 이름이 \(givenName)으로 설정되었습니다.")
                    }
                }
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("🛑 Apple 로그인 실패:", error)
    }
}

// MARK: — ASAuthorizationControllerPresentationContextProviding
extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 키 윈도우 반환
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first!
    }
}
