//  CBIndex.swift
//  TravelGuide
//
//  콘텐츠 기반 근접도 인덱스 (간단 KNN + 코사인 유사도)

import Foundation
import CoreLocation

/// **여행지 특징 벡터**: [x, y, catOneHot...]
private struct FeatureVec {
    let id: String      // Destination.id (String) 사용
    let vec: [Double]
}

final class CBIndex {

    // MARK: - Properties
    private var index: [FeatureVec] = []
    private var catDict: [String: Int] = [:]   // 카테고리 → one-hot 인덱스

    // MARK: - Init
    init(destinations: [Destination]) {
        buildIndex(from: destinations)
    }

    private func buildIndex(from dests: [Destination]) {
        // 1) 카테고리 사전
        dests.map(\.category3).forEach {
            if catDict[$0] == nil { catDict[$0] = catDict.count }
        }
        // 2) 각 dest → 벡터화
        index = dests.map { dest in
            let geo = project(lat: dest.latitude, lon: dest.longitude) // 2D 평면
            var v: [Double] = [geo.x, geo.y]
            // one-hot 카테고리
            let dim = catDict.count
            v.append(contentsOf: Array(repeating: 0, count: dim))
            if let idx = catDict[dest.category3] { v[2 + idx] = 1 }
            return FeatureVec(id: dest.id, vec: v)
        }
    }

    // MARK: - Public
    /// 쿼리 위치·카테고리 → 유사도(0-1) 반환
    func similarity(to destID: String, from queryVec: [Double]) -> Double {
        guard let target = index.first(where: { $0.id == destID }) else {
            return 0
        }
        return cosine(target.vec, queryVec)
    }

    /// 현재 위치 → [x, y] 투영 + 빈 one-hot 로 쿼리벡터 생성
    func queryVector(for loc: CLLocation) -> [Double] {
        let geo = project(lat: loc.coordinate.latitude,
                          lon: loc.coordinate.longitude)
        return [geo.x, geo.y] + Array(repeating: 0, count: catDict.count)
    }

    // MARK: - Helpers
    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        let dot = zip(a, b).map(*).reduce(0, +)
        let mag = sqrt(a.map { $0*$0 }.reduce(0,+)) * sqrt(b.map { $0*$0 }.reduce(0,+))
        return mag == 0 ? 0 : max(0, min(1, dot/mag))
    }

    private func project(lat: Double, lon: Double) -> (x: Double, y: Double) {
        // 간단한 메르카토르(시각화용) – 서울 근처 오차 수m
        let rad = .pi/180.0
        return (x: lon * rad * 6_378_137,
                y: log(tan(.pi/4 + lat*rad/2)) * 6_378_137)
    }
}
