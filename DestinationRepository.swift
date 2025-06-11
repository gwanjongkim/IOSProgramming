//
//  DestinationRepository.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
//
//// DestinationRepository.swift - 근본적 해결책
import Foundation
import CoreLocation

final class DestinationRepository: ObservableObject {
    static let shared = DestinationRepository()
    
    // 메모리 캐시
    @Published private var map: [String: Destination] = [:]
    
    // 🔥 핵심 개선 1: 데이터 로딩 상태 관리
    @Published var isFullyLoaded = false
    private var loadingTask: Task<Void, Never>?
    
    var allDestinations: [Destination] { Array(map.values) }
    subscript(id: String) -> Destination? { map[id] }
    
    private init() {
        // 🔥 핵심 개선 2: 앱 시작시 전체 데이터 미리 로드
        startPreloadingData()
    }
    
    // MARK: - 데이터 설정
    func set(_ list: [Destination]) {
        list.forEach { dest in
            map[dest.id] = dest
        }
    }
    
    func add(_ list: [Destination]) {
        set(list) // 동일한 로직
    }
    
    // MARK: - 🔥 핵심 개선 3: 포괄적 데이터 로딩 시스템
    private func startPreloadingData() {
        loadingTask = Task { @MainActor in
            await loadComprehensiveData()
        }
    }
    
    @MainActor
    private func loadComprehensiveData() async {
        print("🚀 종합 데이터 로딩 시작...")
        let service: DestinationServiceProtocol = TourAPIService()
        
        do {
            var allDestinations: [Destination] = []
            
            // 1️⃣ 전국 주요 지역별 데이터 수집
            let majorAreas = [
                (1, "서울"), (6, "부산"), (4, "대구"), (2, "인천"), (5, "광주"), (3, "대전"), (7, "울산"),
                (8, "세종"), (31, "경기"), (32, "강원"), (33, "충북"), (34, "충남"), (35, "전북"),
                (36, "전남"), (37, "경북"), (38, "경남"), (39, "제주")
            ]
            
            for (areaCode, areaName) in majorAreas {
                print("🗺️ \(areaName) 지역 로딩 중...")
                
                // 각 지역에서 여러 페이지 수집
                for page in 1...3 {
                    let destinations = try await service.fetchList(
                        areaCode: areaCode,
                        page: page,
                        contentTypeId: 0,
                        numOfRows: 100
                    )
                    allDestinations.append(contentsOf: destinations)
                    
                    // API 과부하 방지를 위한 지연
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                }
            }
            
            // 2️⃣ 전체 카테고리별 데이터 수집
            let contentTypes = [12, 14, 15, 25, 28, 32, 38, 39] // 관광지, 문화시설, 축제, 여행코스, 레포츠, 숙박, 쇼핑, 음식점
            
            for contentType in contentTypes {
                print("🏷️ 카테고리 \(contentType) 로딩 중...")
                
                for page in 1...2 {
                    let destinations = try await service.fetchList(
                        areaCode: 0,
                        page: page,
                        contentTypeId: contentType,
                        numOfRows: 50
                    )
                    allDestinations.append(contentsOf: destinations)
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            
            // 3️⃣ 중복 제거 및 저장
            let uniqueDestinations = Array(Set(allDestinations))
            print("✅ 총 \(uniqueDestinations.count)개 목적지 로드 완료")
            
            self.set(uniqueDestinations)
            self.isFullyLoaded = true
            
            print("🎉 종합 데이터 로딩 완료!")
            
        } catch {
            print("❌ 종합 데이터 로딩 실패:", error)
            // 실패해도 기본 데이터라도 로드 시도
            await loadBasicData()
        }
    }
    
    // 🔥 핵심 개선 4: 기본 데이터 로딩 (fallback)
    @MainActor
    private func loadBasicData() async {
        print("📦 기본 데이터 로딩...")
        let service: DestinationServiceProtocol = TourAPIService()
        
        do {
            var basicDestinations: [Destination] = []
            
            // 최소한 주요 지역들의 인기 목적지들
            for page in 1...10 {
                let destinations = try await service.fetchList(
                    areaCode: 0,
                    page: page,
                    contentTypeId: 0,
                    numOfRows: 100
                )
                basicDestinations.append(contentsOf: destinations)
                try await Task.sleep(nanoseconds: 50_000_000)
            }
            
            self.set(basicDestinations)
            self.isFullyLoaded = true
            print("✅ 기본 데이터 \(basicDestinations.count)개 로드 완료")
            
        } catch {
            print("❌ 기본 데이터 로딩도 실패:", error)
            self.isFullyLoaded = true // 더 이상 시도하지 않음
        }
    }
    
    // MARK: - 🔥 핵심 개선 5: 즐겨찾기 전용 보장 시스템
    func ensureFavoriteDataLoaded(_ favoriteIds: Set<String>) async {
        let missingIds = favoriteIds.filter { map[$0] == nil }
        
        guard !missingIds.isEmpty else { return }
        print("🔍 누락된 즐겨찾기 \(missingIds.count)개 검색 중...")
        
        // 누락된 ID들을 찾기 위해 추가 검색
        let service: DestinationServiceProtocol = TourAPIService()
        
        do {
            // 더 광범위한 검색
            for page in 1...20 {
                let destinations = try await service.fetchList(
                    areaCode: 0,
                    page: page,
                    contentTypeId: 0,
                    numOfRows: 100
                )
                
                self.add(destinations)
                
                // 모든 즐겨찾기가 매칭되었는지 확인
                let stillMissing = missingIds.filter { map[$0] == nil }
                if stillMissing.isEmpty {
                    print("✅ 모든 즐겨찾기 데이터 발견!")
                    break
                }
                
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            
        } catch {
            print("❌ 즐겨찾기 데이터 보장 실패:", error)
        }
    }
    
    // MARK: - 기존 Geo helpers
    func nearby(from location: CLLocation, radius: CLLocationDistance = 500) -> [Destination] {
        allDestinations.filter { dest in
            let d = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
            return d.distance(from: location) <= radius
        }
    }
}


