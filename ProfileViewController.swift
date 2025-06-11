// ProfileViewController.swift
// TravelGuide

import UIKit
import FirebaseAuth
import AuthenticationServices

final class ProfileViewController: UIViewController {

    private let authManager = AuthManager.shared

    private let statusLabel = UILabel()
    private let appleLoginButton = ASAuthorizationAppleIDButton()
    private let logoutButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "내 정보"

        setupUI()
        updateUI()

        // Auth 상태 변화를 UI에 반영
        NotificationCenter.default.addObserver(
            forName: .AuthStateDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.updateUI()
        }
    }

    private func setupUI() {
        statusLabel.font = .preferredFont(forTextStyle: .title2)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Apple 로그인 버튼
        appleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        appleLoginButton.addTarget(self, action: #selector(loginWithApple), for: .touchUpInside)

        // 로그아웃 버튼
        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [statusLabel, appleLoginButton, logoutButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            appleLoginButton.widthAnchor.constraint(equalToConstant: 200),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func updateUI() {
        if authManager.isAnonymous {
            statusLabel.text = "비회원 상태입니다."
            appleLoginButton.isHidden = false
            logoutButton.isHidden = true
        } else {
            statusLabel.text = "환영합니다, \(authManager.userName ?? "사용자")님!"
            appleLoginButton.isHidden = true
            logoutButton.isHidden = false
        }
    }

    @objc private func loginWithApple() {
        authManager.startSignInWithAppleFlow()
    }

    @objc private func handleLogout() {
        do {
            try authManager.signOut()
            print("✅ 로그아웃 완료")
        } catch {
            print("❌ 로그아웃 실패:", error)
        }
    }
}

// Auth 상태 변화 알림
extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
}
