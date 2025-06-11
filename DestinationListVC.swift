// DestinationListVC.swift
// TravelGuide

import UIKit

final class DestinationListVC: UIViewController {
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Data
    private typealias Section = Int
    private var dataSource: UITableViewDiffableDataSource<Section, String>!
    private let repo = DestinationRepository.shared

    // MARK: - Filters
    private let regionOptions: [(code: Int, name: String)] = [
        (0, "전체"), (1, "서울"), (2, "인천"), (3, "대전"), (4, "대구"),
        (5, "광주"), (6, "부산"), (7, "울산"), (8, "세종"), (31, "경기"),
        (32, "강원"), (33, "충북"), (34, "충남"), (35, "전북"), (36, "전남"),
        (37, "경북"), (38, "경남"), (39, "제주")
    ]
    private let contentTypeOptions: [(id: Int, name: String)] = [
        (0, "전체"), (12, "관광지"), (14, "문화시설"), (15, "축제/행사"),
        (25, "여행코스"), (28, "레포츠"), (32, "숙박"), (38, "쇼핑"), (39, "음식점")
    ]
    private var selectedRegion: Int = 0
    private var selectedContentType: Int = 0
    private var keyword: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "여행지"
        view.backgroundColor = .systemBackground

        setupUI()
        configureDataSource()
        configureSearchController()
        observeRepositoryState()
        applyCurrentFilter()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // TableView
        tableView.register(DestinationCell.self, forCellReuseIdentifier: DestinationCell.reuseID)
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Spinner
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        // Layout constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Filter Buttons
        let regionBtn = UIBarButtonItem(title: "지역", style: .plain, target: self, action: #selector(showRegionFilter))
        let typeBtn   = UIBarButtonItem(title: "카테고리", style: .plain, target: self, action: #selector(showContentTypeFilter))
        navigationItem.rightBarButtonItems = [typeBtn, regionBtn]

        // Search Controller
        navigationItem.searchController = searchController
    }

    // MARK: - Search Configuration
    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "검색어 입력"
        definesPresentationContext = true
    }

    // MARK: - DataSource Configuration
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, String>(tableView: tableView) { table, ip, id in
            guard let dest = self.repo[id],
                  let cell = table.dequeueReusableCell(withIdentifier: DestinationCell.reuseID, for: ip) as? DestinationCell
            else { return UITableViewCell() }
            cell.configure(with: dest)
            cell.onToggle = {
                FavoritesStore.shared.toggle(id: id)
                self.reload(id: id)
            }
            return cell
        }
        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    // MARK: - Repository Observation
    private func observeRepositoryState() {
        if !repo.isFullyLoaded {
            spinner.startAnimating()
            Task {
                while !repo.isFullyLoaded {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
                spinner.stopAnimating()
                applyCurrentFilter()
            }
        }
    }

    // MARK: - Filtering Logic
    private func applyCurrentFilter() {
        var filtered = repo.allDestinations
        // Region
        if selectedRegion > 0, let regionName = regionOptions.first(where: { $0.code == selectedRegion })?.name {
            filtered = filtered.filter {
                $0.address?.contains(regionName) == true || $0.title.contains(regionName)
            }
        }
        // Content Type
        if selectedContentType > 0 {
            filtered = filtered.filter { $0.contentTypeId == selectedContentType }
        }
        // Keyword
        if !keyword.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(keyword) ||
                $0.address?.localizedCaseInsensitiveContains(keyword) == true
            }
        }
        // Snapshot
        var snap = NSDiffableDataSourceSnapshot<Section, String>()
        snap.appendSections([0])
        snap.appendItems(filtered.map(\.id))
        dataSource.apply(snap, animatingDifferences: true)
    }

    @objc private func showRegionFilter() {
        let ac = UIAlertController(title: "지역 선택", message: nil, preferredStyle: .actionSheet)
        regionOptions.forEach { opt in
            ac.addAction(UIAlertAction(title: opt.name, style: .default) { _ in
                self.selectedRegion = opt.code
                self.applyCurrentFilter()
            })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(ac, animated: true)
    }

    @objc private func showContentTypeFilter() {
        let ac = UIAlertController(title: "카테고리 선택", message: nil, preferredStyle: .actionSheet)
        contentTypeOptions.forEach { opt in
            ac.addAction(UIAlertAction(title: opt.name, style: .default) { _ in
                self.selectedContentType = opt.id
                self.applyCurrentFilter()
            })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(ac, animated: true)
    }

    // MARK: - SearchResultsUpdating
    func updateSearchResults(for controller: UISearchController) {
        keyword = controller.searchBar.text ?? ""
        applyCurrentFilter()
    }

    // MARK: - Helper
    private func reload(id: String) {
        var snap = dataSource.snapshot()
        if snap.itemIdentifiers.contains(id) {
            snap.reloadItems([id])
            dataSource.apply(snap, animatingDifferences: false)
        }
    }
}

// MARK: - UITableViewDelegate
extension DestinationListVC: UITableViewDelegate {
    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        if let id = dataSource.itemIdentifier(for: ip), let dest = repo[id] {
            navigationController?.pushViewController(
                DestinationDetailVC(destination: dest), animated: true
            )
        }
    }
}

// MARK: - UISearchResultsUpdating
extension DestinationListVC: UISearchResultsUpdating {}
