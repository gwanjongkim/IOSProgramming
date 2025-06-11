//
//  RecommendationList.swift
//  TravelGuide
//
//  Created by 관중 mac on 6/8/25.
//

import UIKit
import CoreLocation
import Combine

/// **추천 여행지 목록 화면 (UIKit)**
final class RecommendationListVC: UIViewController {

    // MARK: - UI
    private let tableView = UITableView()
    private enum Section { case main }
    private var dataSource: UITableViewDiffableDataSource<Section, String>!

    // MARK: - 의존성
    private let service: DestinationServiceProtocol = TourAPIService()   // ⭐️ API 서비스
    private let base: Destination?                                       // 특정 기준지(옵션)

    // MARK: - 위치
    private let locationManager = CLLocationManager()
    private var currentLoc: CLLocation?

    // MARK: - Combine
    private var favCancellable: AnyCancellable?

    // MARK: - Init
    init(base: Destination?) {
        self.base = base
        super.init(nibName: nil, bundle: nil)
    }
    convenience init() { self.init(base: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "추천 여행지"
        view.backgroundColor = .systemBackground

        configureTable()
        configureLocationManager()
        observeFavorites()

        // 🔥 저장소 비어 있으면 채우고 → 추천 로드
        Task { await warmUpDataAndLoad() }
    }

    // MARK: - UI 설정
    private func configureTable() {
        tableView.register(DestinationCell.self,
                           forCellReuseIdentifier: DestinationCell.reuseID)
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        dataSource = UITableViewDiffableDataSource(tableView: tableView) {
            [weak self] table, indexPath, id -> UITableViewCell? in
            guard
                let self,
                let dest = DestinationRepository.shared[id],
                let cell = table.dequeueReusableCell(withIdentifier: DestinationCell.reuseID,
                                                     for: indexPath) as? DestinationCell
            else { return nil }

            cell.configure(with: dest)
            cell.onToggle = {
                FavoritesStore.shared.toggle(id: id)
                self.updateRecommendations()}
            return cell
        }
        tableView.delegate = self
    }

    // MARK: - 위치
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - 즐겨찾기 변경 감시
    private func observeFavorites() {
        favCancellable = FavoritesStore.shared.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateRecommendations() }
    }

    // MARK: - 데이터 워밍업 + 추천 호출
    @MainActor
    private func warmUpDataAndLoad() async {
        if DestinationRepository.shared.allDestinations.isEmpty {
            do {
                // ‼️ 실제 API 파라미터는 필요 시 수정
                let list = try await service.fetchList(areaCode: 1, page: 1,contentTypeId: 12, numOfRows: 10)
                DestinationRepository.shared.set(list)
            } catch {
                tableView.setEmptyMessage("데이터를 불러오지 못했습니다.\n다시 시도해 주세요.")
                print("❌ warm-up fetch error:", error)
                return
            }
        }
        updateRecommendations()
    }

    // MARK: - 추천 계산 & 스냅샷
    private func updateRecommendations() {
        // 위치 거부/보류인 경우 안내
       /* guard let loc = currentLoc else {
            tableView.setEmptyMessage("위치 정보를 불러오는 중이에요…")
            return
        }
*/
        // 저장소가 여전히 비면 다시 워밍업
        if DestinationRepository.shared.allDestinations.isEmpty {
            Task { await warmUpDataAndLoad() }
            return
        }

        Task {
            let recs = await RecommendationEngine.shared.recommend(
                near: currentLoc,//loc -> currentLoc
                excluding: FavoritesStore.shared.favorites,
                topK: 10
            )
            applySnapshot(with: recs.map(\.dest))
        }
    }

    @MainActor
    private func applySnapshot(with dests: [Destination]) {
        var snap = NSDiffableDataSourceSnapshot<Section, String>()
        snap.appendSections([.main])
        snap.appendItems(dests.map(\.id))
        dataSource.apply(snap, animatingDifferences: true)

        dests.isEmpty
        ? tableView.setEmptyMessage("근처에서 추천할 여행지를 찾지 못했어요 🥲")
        : tableView.restore()
    }
}

// MARK: - UITableViewDelegate
extension RecommendationListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard
            let id   = dataSource.itemIdentifier(for: indexPath),
            let dest = DestinationRepository.shared[id]
        else { return }
        navigationController?.pushViewController(
            DestinationDetailVC(destination: dest), animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension RecommendationListVC: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        currentLoc = loc
        updateRecommendations()
    }
}

// MARK: - UITableView Empty-State Helper (Optional)
private extension UITableView {
    func setEmptyMessage(_ msg: String) {
        let lbl = UILabel()
        lbl.text  = msg
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.textColor = .secondaryLabel
        backgroundView = lbl
    }
    func restore() { backgroundView = nil }
}
