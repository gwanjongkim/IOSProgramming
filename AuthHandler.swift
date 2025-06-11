//
//  AuthHandler.swift
//  TravelGuide
//
//  Created by 관중 mac on 6/5/25.
//
//  AppleAuthHelper.swift
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import UIKit         // presentationAnchor 용

final class AppleAuthHelper: NSObject {

    private var currentNonce: String?

    // MARK: - Public API
    func start() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        // ───────────── controller ─────────────
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - ASAuthorization Delegate
extension AppleAuthHelper: ASAuthorizationControllerDelegate,
                            ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController)
    -> ASPresentationAnchor {
        // iOS 15+ : keyWindow 가 nil 일 수 있어 connectedScenes 사용
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first!
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization auth: ASAuthorization
    ) {
        guard
            let appleID   = auth.credential as? ASAuthorizationAppleIDCredential,
            let idToken   = appleID.identityToken,
            let idTokenStr = String(data: idToken, encoding: .utf8),
            let nonce     = currentNonce
        else { return }

        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenStr,
            rawNonce: nonce
        )

        if let user = Auth.auth().currentUser, user.isAnonymous {
            // 기존 익명 계정에 연결
            user.link(with: credential) { _, err in
                print(err ?? "✅ 익명 계정 → Apple 계정 연결 완료")
            }
        } else {
            Auth.auth().signIn(with: credential) { _, err in
                print(err ?? "✅ Apple 로그인 완료")
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("❌ Apple 로그인 실패:", error)
    }
}

// MARK: - Utility Helpers
private func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    // Firebase 는 **base64url** 인코딩을 요구
    return Data(hash).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remaining = length

    while remaining > 0 {
        // 16바이트씩 무작위 가져오기
        var randoms = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        guard status == errSecSuccess else { fatalError("Unable to generate nonce.") }

        randoms.forEach { byte in
            if remaining == 0 { return }
            if byte < charset.count {
                result.append(charset[Int(byte)])
                remaining -= 1
            }
        }
    }
    return result
}
