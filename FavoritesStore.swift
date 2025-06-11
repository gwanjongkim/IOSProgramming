//
//  FavoritesStore.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
//
// FavoritesStore.swift
// TravelGuide

import Combine
import FirebaseAuth
import FirebaseFirestore

final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: Set<String> = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var uid: String { AuthManager.shared.uid! }
    private var docRef: DocumentReference { db.collection("users").document(uid) }

    private init() {
        loadLocal()
        listenRemote()
    }

    // MARK: - Public API
    func toggle(id: String) {
        if favorites.contains(id) { favorites.remove(id) }
        else                       { favorites.insert(id) }
        persistLocal()
        syncRemote()
    }

    func contains(id: String) -> Bool { favorites.contains(id) }

    /// SettingViewController 에서 호출되는 메서드
    @MainActor
    func clearAll() {
        favorites.removeAll()
        persistLocal()
        Task {
            do {
                try await docRef.delete()
            } catch {
                print("🔥 Firestore delete error:", error)
            }
        }
    }

    // MARK: - Local Persistence
    private let key = "favoriteIDs"

    private func persistLocal() {
        // String Set 그대로 저장
        UserDefaults.standard.set(Array(favorites), forKey: key)
    }

    private func loadLocal() {
        // UserDefaults에서 String 배열로 직접 로드
        if let array = UserDefaults.standard.stringArray(forKey: key) {
            favorites = Set(array)
        }
    }

    // MARK: - Firestore Sync
    private func syncRemote() {
        // String 배열로 저장
        docRef.setData(["ids": Array(favorites)], merge: true)
    }

    private func listenRemote() {
        listener?.remove()
        listener = docRef.addSnapshotListener { [weak self] snap, _ in
            guard let self = self,
                  let data = snap?.data()?["ids"] as? [String]
            else { return }
            let remote = Set(data)
            if remote != self.favorites {
                self.favorites = remote
                self.persistLocal()
            }
        }
    }
}
