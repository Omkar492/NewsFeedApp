//
//  ViewState.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - Feed View State
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case empty
    case error(AppError)
}

// MARK: - Feed ViewModel
final class FeedViewModel: ObservableObject {
    // MARK: - Outputs
    @Published private(set) var state: ViewState<[Article]> = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var selectedCategory: NewsCategory = .general
    @Published private(set) var trendingArticles: [Article] = []

    // MARK: - Pagination State
    private var currentPage = 1
    private var totalResults = 0
    private var isFetching = false

    var hasMorePages: Bool {
        articles.count < totalResults
    }

    // MARK: - Dependencies
    private let fetchHeadlinesUseCase: FetchHeadlinesUseCaseProtocol
    private let bookmarkUseCase: BookmarkUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(fetchHeadlinesUseCase: FetchHeadlinesUseCaseProtocol,
         bookmarkUseCase: BookmarkUseCaseProtocol) {
        self.fetchHeadlinesUseCase = fetchHeadlinesUseCase
        self.bookmarkUseCase = bookmarkUseCase
    }

    // MARK: - Inputs
    func viewDidLoad() {
        loadFirstPage()
    }

    func selectCategory(_ category: NewsCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        loadFirstPage()
    }

    func refresh() {
        loadFirstPage()
    }

    func loadNextPageIfNeeded(currentItem article: Article) {
        guard let index = articles.firstIndex(of: article) else { return }
        let thresholdIndex = articles.index(articles.endIndex, offsetBy: -3)
        guard index >= thresholdIndex, hasMorePages, !isFetching else { return }
        loadNextPage()
    }

    func toggleBookmark(_ article: Article) {
        bookmarkUseCase.toggleBookmark(article)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] isBookmarked in
                      self?.updateBookmarkState(articleId: article.id, isBookmarked: isBookmarked)
                  })
            .store(in: &cancellables)
    }

    // MARK: - Private
    private func loadFirstPage() {
        currentPage = 1
        articles = []
        totalResults = 0
        isFetching = false
        state = .loading
        fetch(page: 1, isRefresh: true)
    }

    private func loadNextPage() {
        guard !isFetching, hasMorePages else { return }
        isLoadingMore = true
        fetch(page: currentPage + 1, isRefresh: false)
    }

    private func fetch(page: Int, isRefresh: Bool) {
        guard !isFetching else { return }
        isFetching = true

        fetchHeadlinesUseCase.execute(category: selectedCategory, page: page)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    self.isFetching = false
                    self.isLoadingMore = false
                    if case .failure(let error) = completion {
                        if self.articles.isEmpty {
                            self.state = .error(error)
                        }
                        // If we have existing articles, silently fail pagination
                    }
                },
                receiveValue: { [weak self] paginated in
                    guard let self else { return }
                    self.currentPage = paginated.currentPage
                    self.totalResults = paginated.totalResults

                    if isRefresh {
                        self.articles = paginated.articles
                    } else {
                        self.articles.append(contentsOf: paginated.articles)
                    }

                    self.state = self.articles.isEmpty ? .empty : .loaded(self.articles)
                }
            )
            .store(in: &cancellables)
    }

    private func updateBookmarkState(articleId: String, isBookmarked: Bool) {
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            var updatedArticles = articles
            updatedArticles[index].isBookmarked = isBookmarked
            articles = updatedArticles
            state = articles.isEmpty ? .empty : .loaded(articles)
        }
    }
}
