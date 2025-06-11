//
//  SettingsViewController.swift
//  TravelGuide
//
//  Created by ChatGPT-o3 on 6/6/25.
//
//  "회원탈퇴" 화면 – 계정 삭제 & 로컬/원격 데이터 정리
//
//  ✅   프로젝트에 추가하고 AppTabBarController 에서
//  let settingsVC = UINavigationController(rootViewController: SettingsViewController())
//  settingsVC.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
//  viewControllers?.append(settingsVC)
//  …와 같이 네 번째 탭으로 노출해 주세요.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class SettingsViewController: UIViewController {

    // MARK: - UI
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("회원탈퇴", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemRed
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "설정"
        view.backgroundColor = .systemBackground
        configureLayouts()
    }

    private func configureLayouts() {
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        view.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            deleteButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func handleDelete() {
        let alert = UIAlertController(title: "정말로 탈퇴하시겠습니까?",
                                      message: "계정 및 모든 즐겨찾기 정보가 영구 삭제됩니다.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { _ in
            self.performAccountDeletion()
        })
        present(alert, animated: true)
    }

    private func performAccountDeletion() {
        guard let user = Auth.auth().currentUser else { return }

        // 1️⃣ Firestore 사용자 문서 삭제 (즐겨찾기 등)
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { err in
            if let err = err {
                print("🛑 Firestore delete error:", err)
            }
        }

        // 2️⃣ 로컬 데이터 제거
        UserDefaults.standard.removeObject(forKey: "favoriteIDs")
        // FavoritesStore의 clearAll() 메서드 사용 (직접 수정 대신)
        FavoritesStore.shared.clearAll()

        // 3️⃣ Firebase Auth – 계정 삭제
        user.delete { [weak self] error in
            if let error = error {
                // 최근 인증이 필요한 경우 → 로그아웃 후 익명 로그인 시도
                print("🛑 Auth delete error:", error)
                self?.reauthenticateAndDelete(user: user)
            } else {
                self?.showGoodbye()
            }
        }
    }

    /// 최근 로그인 요구 시 – 익명 사용자이거나, Apple 로그인 사용자는 재인증 후 다시 시도
    private func reauthenticateAndDelete(user: User) {
        if user.isAnonymous {
            // 익명 사용자는 signInAnonymously 로 새 계정 → 이후 삭제 가능성이 낮아 그냥 로그아웃 권고
            signOutAndInform()
            return
        }

        // 예시) Apple 재로그인 흐름 (다른 프로바이더라면 별도 처리 필요)
        OAuthProvider(providerID: "apple.com").getCredentialWith(nil) { cred, err in
            if let cred {
                user.reauthenticate(with: cred) { _, error in
                    if let error = error {
                        print("🛑 Re-auth fail:", error)
                        self.showError("재로그인에 실패했습니다. 다시 시도해주세요.")
                    } else {
                        self.performAccountDeletion() // 다시 시도
                    }
                }
            } else {
                print("🛑 Apple credential error:", err ?? "unknown")
                self.showError("재로그인 정보를 가져올 수 없습니다.")
            }
        }
    }

    private func signOutAndInform() {
        do {
            try Auth.auth().signOut()
            AuthManager.shared.signInIfNeeded()   // 익명 계정 재로그인
            showError("최근 로그인 정보가 없어 자동 로그아웃했습니다. 다시 탈퇴를 시도해주세요.")
        } catch {
            showError("로그아웃 중 오류 발생: \(error.localizedDescription)")
        }
    }

    // MARK: – UI Helper
    private func showError(_ msg: String) {
        let alert = UIAlertController(title: "오류", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showGoodbye() {
        let alert = UIAlertController(title: "탈퇴 완료", message: "그동안 이용해주셔서 감사합니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            // 앱 초기 화면으로 이동 (로그아웃 상태)
            AuthManager.shared.signInIfNeeded()
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
