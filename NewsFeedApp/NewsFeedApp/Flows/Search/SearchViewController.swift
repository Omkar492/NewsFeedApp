//
//  SearchViewController.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import UIKit
import Combine

// MARK: - Search View Controller
final class SearchViewController: UIViewController {
    private let viewModel: SearchViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Int, Article>!

    enum Section: Int { case articles = 0 }

    // MARK: - UI
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchBar.placeholder = "Search news, topics, sources…"
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.delegate = self
        sc.searchResultsUpdater = self
        return sc
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .systemBackground
        cv.keyboardDismissMode = .onDrag
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var idleView = EmptyStateView(
        systemImage: "magnifyingglass",
        title: "Search for News",
        subtitle: "Type a keyword to find articles on any topic."
    )

    private lazy var emptyView = EmptyStateView(
        systemImage: "doc.text.magnifyingglass",
        title: "No Results",
        subtitle: "Try a different keyword or check your spelling."
    )

    private lazy var errorView = EmptyStateView(
        systemImage: "exclamationmark.circle",
        title: "Search Failed",
        subtitle: "Please try again.",
        actionTitle: "Retry"
    )

    private let loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        return v
    }()

    // MARK: - Init
    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Search"
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        view.addSubview(collectionView)
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        collectionView.register(ArticleCell.self, forCellWithReuseIdentifier: ArticleCell.reuseIdentifier)
        collectionView.register(LoadingFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: LoadingFooterView.reuseIdentifier)
        collectionView.delegate = self
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Article>(collectionView: collectionView) { [weak self] cv, indexPath, article in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ArticleCell.reuseIdentifier, for: indexPath) as! ArticleCell
            cell.configure(with: article)
            cell.onBookmarkTapped = { [weak self] in self?.viewModel.toggleBookmark(article) }
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }
            let footer = cv.dequeueReusableSupplementaryView(ofKind: kind,
                                                             withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                                                             for: indexPath) as! LoadingFooterView
            footer.configure(isLoading: self?.viewModel.isLoadingMore == true)
            return footer
        }
    }

    // MARK: - Bind
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewModel.$articles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in self?.applySnapshot(articles: articles) }
            .store(in: &cancellables)

        viewModel.$isLoadingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateLoadingFooterVisibility() }
            .store(in: &cancellables)
    }

    private func render(state: ViewState<[Article]>) {
        switch state {
        case .idle:
            loadingView.stopAnimating()
            showOverlay(idleView)
        case .loading:
            loadingView.startAnimating()
            hideOverlays()
        case .loaded:
            loadingView.stopAnimating()
            hideOverlays()
        case .empty:
            loadingView.stopAnimating()
            showOverlay(emptyView)
        case .error(let error):
            loadingView.stopAnimating()
            let ev = EmptyStateView(systemImage: "exclamationmark.circle",
                                    title: "Search Failed",
                                    subtitle: error.errorDescription ?? "Unknown error",
                                    actionTitle: nil)
            showOverlay(ev)
        }
    }

    private func applySnapshot(articles: [Article]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Article>()
        snapshot.appendSections([0])
        snapshot.appendItems(articles)
        snapshot.reconfigureItems(articles)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func showOverlay(_ view: UIView) {
        hideOverlays()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func hideOverlays() {
        [idleView, emptyView, errorView].forEach { $0.removeFromSuperview() }
    }

    private func updateLoadingFooterVisibility() {
        dataSource.apply(dataSource.snapshot(), animatingDifferences: false)
    }

    // MARK: - Layout
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize,
                                                                 elementKind: UICollectionView.elementKindSectionFooter,
                                                                 alignment: .bottom)
        section.boundarySupplementaryItems = [footer]
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UISearchResultsUpdating & UISearchBarDelegate
extension SearchViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchQuerySubject.send(searchController.searchBar.text ?? "")
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.clearSearch()
    }
}

// MARK: - UICollectionViewDelegate
extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let article = dataSource.itemIdentifier(for: indexPath) else { return }
        let detailVM = AppDependencyContainer.shared.makeDetailViewModel(article: article)
        let detailVC = DetailViewController(viewModel: detailVM)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let article = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.loadNextPageIfNeeded(currentItem: article)
    }
}
