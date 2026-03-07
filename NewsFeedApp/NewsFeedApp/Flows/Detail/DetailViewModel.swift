//
//  DetailViewModel.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - Detail ViewModel
final class DetailViewModel {
    @Published private(set) var article: Article
    @Published private(set) var isBookmarked: Bool

    private let bookmarkUseCase: BookmarkUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(article: Article, bookmarkUseCase: BookmarkUseCaseProtocol) {
        self.article = article
        self.isBookmarked = article.isBookmarked
        self.bookmarkUseCase = bookmarkUseCase
    }

    func toggleBookmark() {
        bookmarkUseCase.toggleBookmark(article)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] bookmarked in
                      self?.isBookmarked = bookmarked
                      self?.article.isBookmarked = bookmarked
                  })
            .store(in: &cancellables)
    }

    var shareItems: [Any] {
        var items: [Any] = [article.title]
        if let url = article.url { items.append(url) }
        return items
    }
}
