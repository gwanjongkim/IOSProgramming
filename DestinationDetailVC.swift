//
//  DestinationDetailVC.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
//
import UIKit
import MapKit
import Kingfisher

final class DestinationDetailVC: UIViewController {
    // MARK: - Stored
    private let dest: Destination

    // 🟦 UI 프로퍼티
    private let mapView     = MKMapView()
    private let scrollView  = UIScrollView()
    private let contentStack = UIStackView()
    private let imageView   = UIImageView()
    private let titleLabel  = UILabel()

    // MARK: - Init
    init(destination: Destination) {
        self.dest = destination
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = dest.title

        configureMap()          // 🟦 지도
        configureScrollCard()   // 🟦 카드
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "추천",
                image: UIImage(systemName: "sparkles"),
                primaryAction: UIAction { [weak self] _ in
                    guard let self else { return }
                    let vc = RecommendationListVC(base: self.dest)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
        )
    }

    // MARK: - Map
    private func configureMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        // 핀 & 영역
        let pin = MKPointAnnotation()
        pin.coordinate = dest.coordinate
        pin.title = dest.title
        mapView.addAnnotation(pin)
        mapView.setRegion(
            MKCoordinateRegion(center: pin.coordinate,
                               latitudinalMeters: 1500,
                               longitudinalMeters: 1500),
            animated: false
        )

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(
                equalTo: view.heightAnchor, multiplier: 0.45)   // 상단 45 %
        ])
    }

    // MARK: - Card (Scroll + Stack)
    private func configureScrollCard() {
        // ① 스크롤뷰 추가
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // ② 스택뷰 설정
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill          // 꼭 fill!
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

            // 폭 고정 → 스택뷰가 너비를 알 수 있도록
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        // ③ 콘텐츠 추가
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true

        if let url = dest.thumbnailURL {
            imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            imageView.image = UIImage(systemName: "photo")
        }

        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.numberOfLines = 0
        titleLabel.text = dest.title

        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(routeBtn)   // 기존 lazy var 버튼
    }

    // MARK: – 추천 리스트 버튼(삭제)
    // RecommendationListVC 가 아직 구현되지 않았으므로 일단 기능 보류.
    // 참고: 구현 후 아래처럼 연결하세요.
    /*
    @objc private func showRecommendations() {
        let vc = RecommendationListVC(base: dest)
        navigationController?.pushViewController(vc, animated: true)
    }
    */

    // MARK: – 길찾기 버튼 구성 개선
    private lazy var routeBtn: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "길찾기"
        cfg.image = UIImage(systemName: "map")
        cfg.imagePadding = 6
        let btn = UIButton(configuration: cfg, primaryAction: UIAction { [weak self] _ in
            self?.openInMaps()
        })
        return btn
    }()

    private func openInMaps() {
        let item = MKMapItem(placemark: .init(coordinate: dest.coordinate))
        item.name = dest.title
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
