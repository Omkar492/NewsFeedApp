//
//  SearchViewModel.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - Search ViewModel
final class SearchViewModel {
    // MARK: - Inputs
    let searchQuerySubject = CurrentValueSubject<String, Never>("")

    // MARK: - Outputs
    @Published private(set) var state: ViewState<[Article]> = .idle
    @Published private(set) var articles: [Article] = []
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var searchQuery: String = ""

    // MARK: - Pagination
    private var currentPage = 1
    private var totalResults = 0
    private var isFetching = false
    private var lastQuery = ""

    var hasMorePages: Bool { articles.count < totalResults }

    // MARK: - Dependencies
    private let searchUseCase: SearchArticlesUseCaseProtocol
    private let bookmarkUseCase: BookmarkUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(searchUseCase: SearchArticlesUseCaseProtocol,
         bookmarkUseCase: BookmarkUseCaseProtocol) {
        self.searchUseCase = searchUseCase
        self.bookmarkUseCase = bookmarkUseCase
        setupDebouncedSearch()
    }

    // MARK: - Inputs
    func loadNextPageIfNeeded(currentItem article: Article) {
        guard let index = articles.firstIndex(of: article) else { return }
        let thresholdIndex = articles.index(articles.endIndex, offsetBy: -3)
        guard index >= thresholdIndex, hasMorePages, !isFetching else { return }
        fetchNextPage()
    }

    func toggleBookmark(_ article: Article) {
        bookmarkUseCase.toggleBookmark(article)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] isBookmarked in
                      self?.updateBookmarkState(articleId: article.id, isBookmarked: isBookmarked)
                  })
            .store(in: &cancellables)
    }

    func clearSearch() {
        searchQuerySubject.send("")
        articles = []
        state = .idle
    }

    // MARK: - Private
    private func setupDebouncedSearch() {
        searchQuerySubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchQuery = query
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            articles = []
            state = .idle
            return
        }

        lastQuery = trimmed
        currentPage = 1
        articles = []
        totalResults = 0
        state = .loading
        fetch(query: trimmed, page: 1)
    }

    private func fetchNextPage() {
        guard !isFetching, hasMorePages else { return }
        isLoadingMore = true
        fetch(query: lastQuery, page: currentPage + 1)
    }

    private func fetch(query: String, page: Int) {
        isFetching = true
        searchUseCase.execute(query: query, page: page)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    self.isFetching = false
                    self.isLoadingMore = false
                    if case .failure(let error) = completion {
                        if self.articles.isEmpty {
                            self.state = error == .noResults ? .empty : .error(error)
                        }
                    }
                },
                receiveValue: { [weak self] paginated in
                    guard let self else { return }
                    self.currentPage = paginated.currentPage
                    self.totalResults = paginated.totalResults
                    if page == 1 {
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
