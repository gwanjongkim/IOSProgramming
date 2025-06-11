//
//  DestinationService.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
// DestinationService.swift

import Foundation

// MARK: - Protocol
protocol DestinationServiceProtocol {
    /// - areaCode: 0=전체, 1=서울, 39=제주 등
    /// - page: 1부터 시작
    /// - contentTypeId: 12=관광지, 32=숙박 등
    func fetchList(
        areaCode: Int,
        page: Int,
        contentTypeId: Int,
        numOfRows: Int
    ) async throws -> [Destination]
}

// MARK: - Stub Implementation
final class DestinationStubService: DestinationServiceProtocol {
    func fetchList(
        areaCode: Int,
        page: Int,
        contentTypeId: Int,
        numOfRows: Int
    ) async throws -> [Destination] {
        // 네트워크 지연 모킹
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard
            let url = Bundle.main.url(forResource: "destinations_stub", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            throw URLError(.fileDoesNotExist)
        }
        let list = try JSONDecoder().decode([Destination].self, from: data)
        return list
    }
}
