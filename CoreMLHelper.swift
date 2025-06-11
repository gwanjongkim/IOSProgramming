//
//  CoreMLHelper.swift
//  TravelGuide
//
//  Created by 관중 mac on 6/xx/25.
//
import CoreML
import Vision

/// 이미지 분류 결과
struct MLPrediction {
    let label: String
    let confidence: Float   // 0.0 ~ 1.0
}

final class CoreMLHelper {
    static let shared = CoreMLHelper(); private init() {}

    // MobileNetV2 ‑ 모델 클래스 자동 생성됨.
    // CoreMLHelper.swift  (vnModel 프로퍼티만 교체)

    private lazy var vnModel: VNCoreMLModel = {
        do {
            // .mlmodel 가 빌드되면 .mlmodelc 폴더로 컴파일되어 번들에 포함됨
            guard let url = Bundle.main.url(forResource: "MobileNetV2",
                                            withExtension: "mlmodelc") else {
                fatalError("❌ MobileNetV2.mlmodelc 파일을 찾을 수 없습니다")
            }
            let model = try MLModel(contentsOf: url,
                                    configuration: MLModelConfiguration())
            return try VNCoreMLModel(for: model)
        } catch {
            fatalError("💥 CoreML 모델 로드 실패: \(error)")
        }
    }()

    /// 동기 예측 (간단용)
    func predict(_ cgImage: CGImage) throws -> MLPrediction {
        let request = VNCoreMLRequest(model: vnModel)
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try handler.perform([request])
        guard let best = (request.results as? [VNClassificationObservation])?.first else {
            throw PredictError.noResult
        }
        return .init(label: best.identifier, confidence: best.confidence)
    }
    enum PredictError: Error { case noResult }
}
