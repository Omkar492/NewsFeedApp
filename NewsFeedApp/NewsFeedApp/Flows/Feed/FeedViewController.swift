//
//  FeedViewController.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//

import UIKit
import Combine

// MARK: - Feed View Controller
final class FeedViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: FeedViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    enum Section: Int, CaseIterable {
        case categories
        case articles
    }

    nonisolated enum Item: Hashable, Sendable {
        case category(NewsCategory)
        case article(Article)
    }

    // MARK: - UI
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .systemBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.refreshControl = refreshControl
        return cv
    }()

    private let refreshControl = UIRefreshControl()

    private let loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        return v
    }()

    private lazy var emptyView = EmptyStateView(
        systemImage: "newspaper",
        title: "No Articles",
        subtitle: "Pull to refresh to load the latest news.",
        actionTitle: "Retry"
    )

    private lazy var errorView = EmptyStateView(
        systemImage: "wifi.exclamationmark",
        title: "Couldn't Load News",
        subtitle: "Check your connection and try again.",
        actionTitle: "Retry"
    )

    // MARK: - Init
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "News"
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

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

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        collectionView.register(ArticleCell.self, forCellWithReuseIdentifier: ArticleCell.reuseIdentifier)
        collectionView.register(CategoryFilterCell.self, forCellWithReuseIdentifier: CategoryFilterCell.reuseIdentifier)
        collectionView.register(LoadingFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: LoadingFooterView.reuseIdentifier)

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false

        emptyView.onActionTapped = { [weak self] in self?.viewModel.refresh() }
        errorView.onActionTapped = { [weak self] in self?.viewModel.refresh() }

        collectionView.delegate = self
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] cv, indexPath, item in
            switch item {
            case .category(let category):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: CategoryFilterCell.reuseIdentifier, for: indexPath) as! CategoryFilterCell
                cell.configure(with: category)
                cell.isSelected = category == self?.viewModel.selectedCategory
                return cell
            case .article(let article):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: ArticleCell.reuseIdentifier, for: indexPath) as! ArticleCell
                cell.configure(with: article)
                cell.onBookmarkTapped = { [weak self] in self?.viewModel.toggleBookmark(article) }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter,
                  indexPath.section == Section.articles.rawValue else { return nil }
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

        viewModel.$selectedCategory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadCategories() }
            .store(in: &cancellables)
    }

    private func render(state: ViewState<[Article]>) {
        refreshControl.endRefreshing()

        switch state {
        case .idle:
            loadingView.stopAnimating()
            hideOverlays()
        case .loading:
            if viewModel.articles.isEmpty {
                loadingView.startAnimating()
            }
            hideOverlays()
        case .loaded:
            loadingView.stopAnimating()
            hideOverlays()
        case .empty:
            loadingView.stopAnimating()
            showOverlay(emptyView)
        case .error(let error):
            loadingView.stopAnimating()
            errorView = EmptyStateView(systemImage: "wifi.exclamationmark",
                                       title: "Couldn't Load News",
                                       subtitle: error.errorDescription ?? "",
                                       actionTitle: "Retry")
            errorView.onActionTapped = { [weak self] in self?.viewModel.refresh() }
            showOverlay(errorView)
        }
    }

    private func applySnapshot(articles: [Article]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.categories, .articles])
        let categoryItems = NewsCategory.allCases.map(Item.category)
        let articleItems = articles.map(Item.article)
        snapshot.appendItems(categoryItems, toSection: .categories)
        snapshot.appendItems(articleItems, toSection: .articles)
        snapshot.reconfigureItems(categoryItems + articleItems)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func reloadCategories() {
        var snapshot = dataSource.snapshot()
        let categoryItems = snapshot.itemIdentifiers(inSection: .categories)
        snapshot.reloadItems(categoryItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateLoadingFooterVisibility() {
        dataSource.apply(dataSource.snapshot(), animatingDifferences: false)
    }

    private func showOverlay(_ view: UIView) {
        hideOverlays()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    private func hideOverlays() {
        [emptyView, errorView].forEach { $0.removeFromSuperview() }
    }

    @objc private func handleRefresh() {
        viewModel.refresh()
    }

    // MARK: - Layout
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .categories:
                return self?.makeCategorySection()
            case .articles:
                return self?.makeArticlesSection()
            }
        }
    }

    private func makeCategorySection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(36))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(36))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        return section
    }

    private func makeArticlesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0

        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]
        return section
    }
}

// MARK: - UICollectionViewDelegate
extension FeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .category(let category):
            collectionView.deselectItem(at: indexPath, animated: true)
            viewModel.selectCategory(category)
        case .article(let article):
            let detailVM = AppDependencyContainer.shared.makeDetailViewModel(article: article)
            let detailVC = DetailViewController(viewModel: detailVM)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard case .article(let article)? = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.loadNextPageIfNeeded(currentItem: article)
    }
}
