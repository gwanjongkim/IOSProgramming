//
//  CFModel.swift
//  TravelGuide
//
//  Created by 관중 mac on 6/8/25.
//  개인화 협업필터링 점수 계산 (MLRecommender)
//
import Foundation
import CoreML

/// **MLRecommender 래퍼**
/// - .mlmodel(c) 파일명은 project 설정에 맞춰 교체하세요.
final class CFModel {

    // MARK: - Properties
    private let model: MLModel
    /// 사용자 식별자 – 익명 UID (AuthManager 가 관리)
    private var uid: String { AuthManager.shared.uid ?? "guest" }

    // MARK: - Init
    init(modelName: String = "UserItemRecommender") throws {
        // ① .mlmodelc 먼저 탐색
        if let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
            model = try MLModel(contentsOf: url)
        }
        // ② 없으면 .mlmodel → 런타임 컴파일
        else if let src = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
            let compiled = try MLModel.compileModel(at: src)
            model = try MLModel(contentsOf: compiled)
        } else {
            throw NSError(domain: "CFModel", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "❌ \(modelName).mlmodel(c) not found"])
        }
    }

    // MARK: - Public
    /// 사용자-아이템 점수 반환 (0-1 스케일·없으면 0)
    func score(item id: String) -> Double {
        guard
            let out = try? model.prediction(
                from: MLDictionaryFeatureProvider(dictionary: [
                    "userId": uid,
                    "itemId": id     // MLRecommender 는 String key 사용
                ])),
            let val = out.featureValue(for: "rating")?.doubleValue
        else { return 0 }
        return val
    }
}
