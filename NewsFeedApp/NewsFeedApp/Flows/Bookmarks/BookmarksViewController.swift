//
//  BookmarksViewController.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import UIKit
import Combine

// MARK: - Bookmarks View Controller
final class BookmarksViewController: UIViewController {
    private let viewModel: BookmarksViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Int, Article>!

    // MARK: - UI
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .systemBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var emptyView = EmptyStateView(
        systemImage: AppConstants.Symbols.bookmark,
        title: AppConstants.Messages.bookmarksEmptyTitle,
        subtitle: AppConstants.Messages.bookmarksEmptySubtitle
    )

    private let loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        return v
    }()

    // MARK: - Init
    init(viewModel: BookmarksViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = AppConstants.Titles.bookmarks
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

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
        collectionView.delegate = self
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Article>(collectionView: collectionView) { [weak self] cv, indexPath, article in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ArticleCell.reuseIdentifier, for: indexPath) as! ArticleCell
            cell.configure(with: article)
            cell.onBookmarkTapped = { [weak self] in
                self?.viewModel.removeBookmark(article)
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
            }
            return cell
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
    }

    private func render(state: ViewState<[Article]>) {
        switch state {
        case .loading:
            loadingView.startAnimating()
            emptyView.removeFromSuperview()
        case .loaded:
            loadingView.stopAnimating()
            emptyView.removeFromSuperview()
        case .empty:
            loadingView.stopAnimating()
            showEmptyView()
        case .error(let error):
            loadingView.stopAnimating()
            showError(error)
        case .idle:
            break
        }
    }

    private func applySnapshot(articles: [Article]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Article>()
        snapshot.appendSections([0])
        snapshot.appendItems(articles)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func showEmptyView() {
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func showError(_ error: AppError) {
        let alert = UIAlertController(title: AppConstants.Titles.error,
                                      message: error.errorDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppConstants.Messages.ok, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Layout
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(AppConstants.Layout.estimatedArticleHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(AppConstants.Layout.estimatedArticleHeight))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDelegate
extension BookmarksViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let article = dataSource.itemIdentifier(for: indexPath) else { return }
        let detailVM = AppDependencyContainer.shared.makeDetailViewModel(article: article)
        let detailVC = DetailViewController(viewModel: detailVM)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // Swipe to delete
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let article = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let delete = UIAction(title: AppConstants.Messages.removeBookmark,
                                  image: UIImage(systemName: AppConstants.Symbols.bookmarkSlash),
                                  attributes: .destructive) { [weak self] _ in
                self?.viewModel.removeBookmark(article)
            }
            return UIMenu(title: "", children: [delete])
        }
    }
}
