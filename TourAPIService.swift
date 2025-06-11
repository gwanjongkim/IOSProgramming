//  TourAPIService.swift
//  TravelGuide

import Foundation

/// API 인증키 관리
enum APIKey {
    static let tour = "ASIE+ykWu+VUtipQ9bql3ZAq1olJEVEFJCx2W+Zi/mJ4peteAl9o1GrPxPQ3Mc9byZi5kk/8Koh/aDA8dKdUow=="
}

// MARK: - JSON 응답 모델
private struct TourListResponse: Decodable {
    let response: Response
    struct Response: Decodable { let body: Body }
    struct Body: Decodable { let items: Items }

    /// items가 빈 문자열로 올 경우에도 안전하게 파싱
    struct Items: Decodable {
        let item: [Item]
        var asArray: [Item] { item }
        private enum CodingKeys: String, CodingKey { case item }
        init(from decoder: Decoder) throws {
            // 객체 형태일 때는 item 키로 디코딩
            if let container = try? decoder.container(keyedBy: CodingKeys.self) {
                self.item = try container.decodeIfPresent([Item].self, forKey: .item) ?? []
            } else {
                // 문자열 등 그 외 타입일 때 빈 배열
                _ = try? decoder.singleValueContainer().decode(String.self)
                self.item = []
            }
        }
    }

    struct Item: Decodable {
        let contentid: String
        let title: String
        let mapx: String
        let mapy: String
        let firstimage: String?
        let firstimage2: String?
        let cat3: String
        let addr1: String?
        let contenttypeid: String
    }
}

// MARK: - 네트워크 서비스 구현
enum TourAPIError: Error, LocalizedError {
    case serviceKeyError(String)
    case xmlResponse(String)
    case noData
    var errorDescription: String? {
        switch self {
        case .serviceKeyError(let msg): return "서비스 키 오류: \(msg)"
        case .xmlResponse(let content): return "XML 응답 수신: \(content)"
        case .noData: return "데이터 없음"
        }
    }
}

final class TourAPIService: DestinationServiceProtocol {
    private let serviceKey = APIKey.tour
    private let session    = URLSession.shared

    /// 공공데이터 API 호출
    func fetchList(
        areaCode: Int = 1,
        page: Int = 1,
        contentTypeId: Int = 12,
        numOfRows: Int = 10
    ) async throws -> [Destination] {
        // URL 구성
        var extra: [String:String] = [
               "numOfRows": "\(numOfRows)",
               "pageNo":    "\(page)"
           ]
           // areaCode, contentTypeId가 0(전체)이면 쿼리에 포함시키지 않음
           if areaCode > 0 {
             extra["areaCode"] = "\(areaCode)"
           }
           if contentTypeId > 0 {
             extra["contentTypeId"] = "\(contentTypeId)"
           };        let url = try buildURL(path: "areaBasedList2", extraQuery: extra)
        print("🔍 TourAPI URL: \(url)")

        // 요청
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
            print("❌ HTTP status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw URLError(.badServerResponse)
        }

        // 디버그용 응답 프린트
        if let str = String(data: data, encoding: .utf8) {
            print("📄 API Response: \(str.prefix(500))")
        }

        // XML 에러 응답 처리
        if let str = String(data: data, encoding: .utf8), str.hasPrefix("<") {
            if str.contains("SERVICE_KEY_IS_NOT_REGISTERED_ERROR") {
                throw TourAPIError.serviceKeyError("서비스 키가 등록되지 않았습니다.")
            } else {
                throw TourAPIError.xmlResponse(String(str.prefix(200)))
            }
        }

        // JSON 디코딩
        let api = try JSONDecoder.tour.decode(TourListResponse.self, from: data)
        return api.response.body.items.asArray.compactMap { Self.destination(from: $0) }
    }

    /// URL 생성 헬퍼
    private func buildURL(path: String, extraQuery: [String:String]) throws -> URL {
        var comp = URLComponents()
        comp.scheme = "https"
        comp.host   = "apis.data.go.kr"
        comp.path   = "/B551011/KorService2/\(path)"

        var items = [
            URLQueryItem(name: "serviceKey", value: serviceKey),
            URLQueryItem(name: "MobileOS", value: "IOS"),
            URLQueryItem(name: "MobileApp", value: "TravelGuide"),
            URLQueryItem(name: "_type", value: "json")
        ] + extraQuery.map { URLQueryItem(name: $0.key, value: $0.value) }

        comp.queryItems = items
        if let enc = comp.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") {
            comp.percentEncodedQuery = enc
        }
        guard let url = comp.url else { throw URLError(.badURL) }
        return url
    }

    /// 응답 모델 → Domain 변환
    private static func destination(from i: TourListResponse.Item) -> Destination? {
        guard let lat = Double(i.mapy), let lon = Double(i.mapx) else { return nil }
        //let uuid = UUID(uuidString: i.contentid) ?? UUID()
        let id = i.contentid
        let raw  = i.firstimage2 ?? i.firstimage ?? ""
        let thumbURL = URL(string: raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        let typeId = Int(i.contenttypeid) ?? 0
        return Destination(
            id: id,
            title: i.title,
            latitude: lat,
            longitude: lon,
            thumbnailURL: thumbURL,
            category3: i.cat3,
            address: i.addr1,
            contentTypeId: typeId
        )
    }
}

// MARK: - JSONDecoder Helper
private extension JSONDecoder {
    static var tour: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
}
