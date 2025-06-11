import UIKit
import ARKit
import SceneKit
import CoreLocation

final class ARCompassViewController: UIViewController {

    private let sceneView = ARSCNView()
    private let statusLabel = UILabel()

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AR 나침반"
        view.backgroundColor = .black

        configureSceneView()
        configureStatusLabel()
        configureCompassEmoji()
        configureLocationManager()
        checkARSupport()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            sceneView.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        updateStatus("AR 세션 일시정지")
    }

    private func configureSceneView() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.delegate  = self
        sceneView.scene     = SCNScene()
        sceneView.autoenablesDefaultLighting   = true
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureStatusLabel() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text              = "AR 초기화 중…"
        statusLabel.textColor         = .white
        statusLabel.backgroundColor   = UIColor.black.withAlphaComponent(0.7)
        statusLabel.textAlignment     = .center
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds     = true
        statusLabel.numberOfLines     = 0
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func configureCompassEmoji() {
        let compass = UILabel()
        compass.text = "🧭"
        compass.font = .systemFont(ofSize: 40)
        compass.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compass)
        NSLayoutConstraint.activate([
            compass.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            compass.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
    }

    private func checkARSupport() {
        guard ARWorldTrackingConfiguration.isSupported else {
            updateStatus("이 기기는 AR을 지원하지 않습니다.")
            return
        }
        updateStatus("AR 지원 확인. 위치·카메라 권한을 허용하세요.")
    }

    private func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let cfg = ARWorldTrackingConfiguration()
        cfg.worldAlignment = .gravityAndHeading
        sceneView.session.run(cfg, options: [.resetTracking, .removeExistingAnchors])
        updateStatus("AR 세션 시작")
        DispatchQueue.main.asyncAfter(deadline: .now()+3) { [weak self] in
            self?.statusLabel.isHidden = true
        }
    }

    private func updateStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.statusLabel.isHidden = false
            self.statusLabel.text    = msg
            print("🛈 ARStatus >", msg)
        }
    }

    private func addCompassNodeOnce() {
        let base  = SCNCylinder(radius: 0.1, height: 0.02)
        base.firstMaterial?.diffuse.contents = UIColor.systemBlue
        let baseNode = SCNNode(geometry: base)

        let arrow  = SCNCone(topRadius: 0, bottomRadius: 0.02, height: 0.1)
        arrow.firstMaterial?.diffuse.contents = UIColor.systemRed
        let arrowNode = SCNNode(geometry: arrow)
        arrowNode.position = SCNVector3(0, 0.06, 0)

        let comp = SCNNode()
        comp.addChildNode(baseNode)
        comp.addChildNode(arrowNode)
        comp.position = SCNVector3(0, 0, -1)   // 1m 앞

        sceneView.scene.rootNode.addChildNode(comp)
    }

    private func updateNearbyPOI() {
        guard let loc = currentLocation else { return }
        let originCoord = loc.coordinate
        
        // (1) 반경 500m 이내의 POI를 가져온다
        let list = DestinationRepository.shared.nearby(from: loc, radius: 500)
        print("📍 근처 \(list.count)개 →", list.map(\.title))
        
        // (2) 기존에 추가했던 AR 노드가 있으면 제거 (새로 리프레시)
        sceneView.scene.rootNode.childNodes.forEach { node in
            // 우리가 추가한 노드는 name == "poiNode" 로 태그해뒀다고 가정
            if node.name == "poiNode" {
                node.removeFromParentNode()
            }
        }
        
        // (3) 주변 POI마다 AR 노드를 생성해서 추가
        for dest in list {
            let destCoord = CLLocationCoordinate2D(latitude: dest.latitude,
                                                    longitude: dest.longitude)
            // 3-1) 실제 거리(미터)와 방위각(도)을 계산
            let dist = distanceMeters(from: originCoord, to: destCoord)
            let bearing = bearingDegrees(from: originCoord, to: destCoord)
            
            // (테스트용) 500m 이내만 화면에 띄우고, 거리가 너무 가까우면 속도를 위해 10m 단위로 잡기
            guard dist >= 10 else { continue }
            
            // 3-2) AR 상의 거리(scaleFactor) 계산 (실제 거리/10 → AR 위 50m 이내)
            let scaleFactor: Float = Float(dist / 10.0)
            // radian으로 변환 (AR 좌표계는 북쪽이 -Z)
            let bearingRad = Float(bearing * .pi / 180)
            
            // 3-3) AR 좌표(x, z) 계산
            let x = sin(bearingRad) * scaleFactor
            let z = -cos(bearingRad) * scaleFactor
            
            // 3-4) 간단한 Billboard 노드 생성 (SCNText나 SCNPlane + 이미지)
            // 3-1) SCNPlane(이미지) 생성
                   //    0.2m x 0.2m 크기의 평면으로 생성
            let plane = SCNPlane(width: 0.2, height: 0.2)
            plane.firstMaterial?.diffuse.contents = UIColor.systemGray   // 기본 placeholder 색상

            // 3-2) 노드 생성 및 기본 위치 설정
            let planeNode = SCNNode(geometry: plane)
            planeNode.name = "poiNode"  // 나중에 지울 때 편하게 찾으려고
            planeNode.position = SCNVector3(x, 0, z)

            // 3-3) 항상 카메라를 바라보도록 BillboardConstraint 설정
            let billboard = SCNBillboardConstraint()
            billboard.freeAxes = [.Y]  // Y축 기준으로만 회전
            planeNode.constraints = [billboard]

            // 3-4) 노드에 “dest.id”를 저장해 두면, 터치 이벤트에서 어떤 POI인지 식별하기 편함
            planeNode.categoryBitMask = dest.id.hashValue  // (간단한 식별 예시)
                   
            // 3-5) Scene에 추가
            sceneView.scene.rootNode.addChildNode(planeNode)

            // 3-6) Kingfisher로 이미지 비동기 로드 → SCNPlane에 입히기
            if let url = dest.thumbnailURL {
                // KingfisherManager.shared.retrieveImage(...) 나, URLSession 데이터 작업 사용 가능
                let task = URLSession.shared.dataTask(with: url) { data, resp, err in
                    guard let data = data, let uiImage = UIImage(data: data) else {
                        print("❌ 이미지 로드 실패 for \(dest.title)")
                        return
                    }
                    DispatchQueue.main.async {
                        plane.firstMaterial?.diffuse.contents = uiImage
                    }
                }
                task.resume()
            } else {
                // 썸네일 URL이 없으면, 기본 아이콘을 넣어 둘 수도 있음
                plane.firstMaterial?.diffuse.contents = UIImage(systemName: "photo")
            }
        }
    }

    // 예시: 단일 POI를 앞에 1.5m 거리만큼 띄우는 헬퍼
    private func placePOINode(dest: Destination, xOffset: Float) {
        let text = SCNText(string: dest.title, extrusionDepth: 0.01)
        text.firstMaterial?.diffuse.contents = UIColor.yellow
        text.font = UIFont.systemFont(ofSize: 0.1, weight: .bold)

        let textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(0.15, 0.15, 0.15)
        // index 0 → xOffset = -0.5, index 1 → xOffset = 0.0, index 2 → xOffset = 0.5
        textNode.position = SCNVector3(xOffset, 0, -1.5)

        sceneView.scene.rootNode.addChildNode(textNode)
    }

}

// MARK: - ARSCNViewDelegate
extension ARCompassViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        updateStatus("AR 오류: \(error.localizedDescription)")
    }
    func sessionWasInterrupted(_ session: ARSession) {
        updateStatus("AR 세션 중단")
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        updateStatus("AR 세션 재개")
        startARSession()
    }
}

// MARK: - CLLocationManagerDelegate
extension ARCompassViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            updateStatus("위치 권한 승인")
            manager.startUpdatingLocation()
            addCompassNodeOnce()  // 권한 승인 시 나침반 노드 한 번 추가
        case .denied, .restricted:
            updateStatus("위치 권한이 필요합니다")
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentLocation = loc
        updateNearbyPOI()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        // 가장 앞에 있는 SCNNode를 가져옴
        if let hitNode = hitResults.first?.node,
           hitNode.name == "poiNode" {
            // hitNode.categoryBitMask에 저장했던 dest.id 값을 찾아서, Destination 객체 검색
            let tappedHash = hitNode.categoryBitMask
            // DestinationRepository를 순회하면서 hashValue 매칭
            if let tappedDest = DestinationRepository.shared.allDestinations.first(where: {
                $0.id.hashValue == tappedHash
            }) {
                // 상세 화면으로 Push
                let detailVC = DestinationDetailVC(destination: tappedDest)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }
}

/// 두 좌표 간 방위각(도 단위)을 반환 (0° = 북쪽, 시계방향 증가)
func bearingDegrees(from origin: CLLocationCoordinate2D,
                    to destination: CLLocationCoordinate2D) -> Double {
    let lat1 = origin.latitude * .pi / 180
    let lon1 = origin.longitude * .pi / 180
    let lat2 = destination.latitude * .pi / 180
    let lon2 = destination.longitude * .pi / 180

    let dLon = lon2 - lon1
    // 방위각(rad)
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let rad = atan2(y, x)
    // rad → deg (0° ~ 360°)
    var deg = rad * 180 / .pi
    if deg < 0 { deg += 360 }
    return deg
}

/// 두 좌표 간 거리를 미터 단위로 반환
func distanceMeters(from origin: CLLocationCoordinate2D,
                    to destination: CLLocationCoordinate2D) -> Double {
    let loc1 = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
    let loc2 = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
    return loc1.distance(from: loc2)  // 미터 단위
}
