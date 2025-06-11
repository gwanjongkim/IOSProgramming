//
//  Destination.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
//

//  Destination.swift
//  TravelGuide
import Foundation
import CoreLocation

struct Destination: Identifiable, Hashable, Codable {
    // 1. **UUID** 로 고정
    let id: String

    let title: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let thumbnailURL: URL?
    let category3: String
    let address: String?        // 🔹 주소 필터링을 위한 새 프로퍼티
    let contentTypeId: Int
    // 2. 편의 프로퍼티
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }

    /// 즐겨찾기 여부 – `FavoritesStore`가 UUID를 사용하도록 맞춰 둡UUI니다.
    var isFavorite: Bool {
        FavoritesStore.shared.contains(id: id)
    }
}
