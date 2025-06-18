//
//  DestinationCell.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
//

import UIKit
import Kingfisher
import Combine

final class DestinationCell: UITableViewCell {
    static let reuseID = "DestinationCell"

    // UI
    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let starButton = UIButton(type: .system)

    // 즐겨찾기 토글 이벤트를 VC로 넘길 클로저
    var onToggle: (() -> Void)?

    private var favCancellable: AnyCancellable?
    private var currentID: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureLayouts()
    }
    required init?(coder: NSCoder) { fatalError() }

    // 레이아웃
    private func configureLayouts() {
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.backgroundColor = .systemGray5
        thumb.layer.cornerRadius = 8
        thumb.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        starButton.translatesAutoresizingMaskIntoConstraints = false
        starButton.tintColor = .systemYellow
        starButton.addTarget(self, action: #selector(starTapped), for: .touchUpInside)

        contentView.addSubview(thumb)
        contentView.addSubview(titleLabel)
        contentView.addSubview(starButton)

        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 60),
            thumb.heightAnchor.constraint(equalTo: thumb.widthAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            starButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            starButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            starButton.widthAnchor.constraint(equalToConstant: 28),
            starButton.heightAnchor.constraint(equalTo: starButton.widthAnchor)
        ])
    }

    // ★ 표시 갱신
    private func updateStar(isFav: Bool) {
        let imgName = isFav ? "star.fill" : "star"
        starButton.setImage(UIImage(systemName: imgName), for: .normal)
    }

    func configure(with destination: Destination) {
        currentID = destination.id
        favCancellable?.cancel()
        favCancellable = FavoritesStore.shared.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favs in
                guard let self, let id = self.currentID else { return }
                self.updateStar(isFav: favs.contains(id))
            }
        
        titleLabel.text = destination.title
        updateStar(isFav: FavoritesStore.shared.contains(id: destination.id))

        if let url = destination.thumbnailURL {
            let options: KingfisherOptionsInfo = [
                        .transition(.fade(0.2)),
                        .cacheOriginalImage,
                        .backgroundDecode,                    // 백그라운드에서 디코드
                        .callbackQueue(.mainAsync),           // 메인 큐에서 콜백
                        .retryStrategy(DelayRetryStrategy(    // 재시도 전략
                            maxRetryCount: 3,
                            retryInterval: .seconds(2)
                        ))
                    ]
            
            thumb.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: options
            ) { [weak self] result in
                switch result {
                case .success(let imageResult):
                    print("✅ 이미지 로드 성공: \(imageResult.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("❌ 이미지 로드 실패: \(error.localizedDescription)")
                    // 실패 시 기본 이미지 설정
                    DispatchQueue.main.async {
                        self?.thumb.image = UIImage(systemName: "photo")
                    }
                }
            }
        } else {
            thumb.image = UIImage(systemName: "photo")
        }
    }

    @objc private func starTapped() {
        onToggle?()               // VC 에게 알려주기
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumb.kf.cancelDownloadTask()
        thumb.image = nil
        favCancellable?.cancel()
        favCancellable = nil
        currentID = nil
        onToggle = nil
    }
}
