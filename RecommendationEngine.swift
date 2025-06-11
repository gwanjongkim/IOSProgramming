//
//  RecommendationEngine.swift
//  TravelGuide
//
//  Created by 관중 mac on 6/8/25.
//
//
//  RecommendationEngine.swift
//  TravelGuide
//
//  CF + CB + Geo 가중 합성 스코어링
//
import Foundation
import CoreLocation

struct Recommendation: Identifiable {
    var id: String { dest.id }
    let dest: Destination
    let score: Double
}

@MainActor
final class RecommendationEngine {

    // MARK: - Singleton
    static let shared = RecommendationEngine()
    private init() {
        // 저장소 준비될 때 인덱스 빌드
        buildIndexIfNeeded()
    }

    // MARK: - Models
    private var cf: CFModel?
    private var cb: CBIndex?
    private func loadModelsIfNeeded() {
        if cf == nil { cf = try? CFModel(modelName: "UserItemRecommender") }
        // cb 는 DestinationRepository 가 채워진 뒤 buildIndexIfNeeded() 로 생성
    }

    // MARK: - Index
    private func buildIndexIfNeeded() {
        let repo = DestinationRepository.shared
        guard !repo.allDestinations.isEmpty else { return }
        cb = CBIndex(destinations: repo.allDestinations)
    }

    // DestinationRepository 가 새로 세트될 때 호출해 주세요.
    func refreshIndex() { buildIndexIfNeeded() }

    // MARK: - Public API
    func recommend(
        near loc: CLLocation?,
        excluding fav: Set<String> = [],
        topK k: Int = 10
    ) async -> [Recommendation] {

        loadModelsIfNeeded()
        buildIndexIfNeeded()

        let repo = DestinationRepository.shared
        guard !repo.allDestinations.isEmpty else { return [] }

        // 후보 필터
        let candidates = repo.allDestinations.filter { !fav.contains($0.id) }
        guard !candidates.isEmpty else { return [] }

        // 쿼리 벡터(콘텐츠 기반)
        let qVec = loc.flatMap { cb?.queryVector(for: $0) }

        // 스코어링
        let recs = candidates.map { dest -> Recommendation in
            // CF 점수 (0-1)
            let cfScore = cf?.score(item: dest.id) ?? 0
            // CB 점수 (0-1)
            let cbScore = (qVec != nil) ? (cb?.similarity(to: dest.id, from: qVec!) ?? 0) : 0
            // Geo 가우시안 (0-1)
            let geoScore: Double
            if let l = loc {
                let dist = CLLocation(latitude: dest.latitude,
                                      longitude: dest.longitude)
                            .distance(from: l)            // m
                let sigma = 500.0                         // 500 m 기준
                geoScore = exp(-pow(dist/sigma, 2))
            } else { geoScore = 0 }

            let final = 0.55*cfScore + 0.35*cbScore + 0.10*geoScore
            return Recommendation(dest: dest, score: final)
        }

        return Array(recs.sorted { $0.score > $1.score }.prefix(k))
    }
}
