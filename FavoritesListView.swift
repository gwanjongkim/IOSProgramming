// FavoritesListView.swift
// TravelGuide// FavoritesListView.swift
// TravelGuide

import SwiftUI

struct FavoritesListView: View {
    @ObservedObject private var store = FavoritesStore.shared
    @ObservedObject private var repo  = DestinationRepository.shared
    @State private var selected: Destination?
    @State private var didLoad = false
    @State private var isLoading = false

    private let service: DestinationServiceProtocol = TourAPIService()

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("데이터 로딩 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.favorites.isEmpty {
                    VStack {
                        Image(systemName: "star")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("즐겨찾기가 없습니다")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("여행지 목록에서 별 아이콘을 눌러\n즐겨찾기에 추가해보세요")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("즐겨찾기") {
                            ForEach(matchedDestinations, id: \.id) { dest in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dest.title)
                                            .font(.headline)
                                        Text("ID: \(dest.id.prefix(8))…")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { selected = dest }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.toggle(id: dest.id)
                                    } label: {
                                        Label("삭제", systemImage: "star.slash.fill")
                                    }
                                }
                            }
                        }
                        if !unmatchedFavoriteIds.isEmpty {
                            Section(header: Text("매칭되지 않은 즐겨찾기")) {
                                ForEach(Array(unmatchedFavoriteIds), id: \.self) { id in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("❌ 매칭 실패")
                                                .foregroundColor(.red)
                                            Text("ID: \(id.prefix(8))…")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button("삭제") {
                                            store.toggle(id: id)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("즐겨찾기")
            .onAppear { loadDataIfNeeded() }
            .sheet(item: $selected) { dest in
                DetailWrapper(destination: dest)
            }
        }
    }

    // 매칭된 목적지
    private var matchedDestinations: [Destination] {
        store.favorites
            .compactMap { repo[$0] }
            .sorted { $0.title < $1.title }
    }

    // 매칭되지 않은 즐겨찾기 ID들
    private var unmatchedFavoriteIds: Set<String> {
        let matchedIds = Set(matchedDestinations.map(\.id))
        return store.favorites.subtracting(matchedIds)
    }

    // 전체 데이터 로드 (한 번만)
    private func loadDataIfNeeded() {
        guard !didLoad && !store.favorites.isEmpty else { return }
        didLoad = true
        isLoading = true

        Task {
            do {
                let all = try await service.fetchList(
                    areaCode:      0,
                    page:          1,
                    contentTypeId: 0,
                    numOfRows:     max(store.favorites.count, 10)
                )
                repo.set(all)
            } catch {
                print("❌ Favorites load error:", error)
            }
            await MainActor.run { isLoading = false }
        }
    }
}

// UIKit VC → SwiftUI로 감싸기
typealias DetailWrapper = DestinationDetailWrapper

struct DestinationDetailWrapper: UIViewControllerRepresentable {
    let destination: Destination
    func makeUIViewController(context: Context) -> UIViewController {
        DestinationDetailVC(destination: destination)
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
