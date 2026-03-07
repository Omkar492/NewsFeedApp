//
//  BookmarksViewModel.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//
import Foundation
import Combine

// MARK: - Bookmarks ViewModel
final class BookmarksViewModel {
    @Published private(set) var state: ViewState<[Article]> = .idle
    @Published private(set) var articles: [Article] = []

    private let bookmarkUseCase: BookmarkUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(bookmarkUseCase: BookmarkUseCaseProtocol) {
        self.bookmarkUseCase = bookmarkUseCase
    }

    func viewDidAppear() {
        loadBookmarks()
    }

    func removeBookmark(_ article: Article) {
        bookmarkUseCase.toggleBookmark(article)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] _ in
                      self?.articles.removeAll { $0.id == article.id }
                      if self?.articles.isEmpty == true {
                          self?.state = .empty
                      }
                  })
            .store(in: &cancellables)
    }

    private func loadBookmarks() {
        state = .loading
        bookmarkUseCase.fetchBookmarks()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state = .error(error)
                    }
                },
                receiveValue: { [weak self] articles in
                    self?.articles = articles
                    self?.state = articles.isEmpty ? .empty : .loaded(articles)
                }
            )
            .store(in: &cancellables)
    }
}
