//
//  FetchHeadlinesUseCaseProtocol.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - Fetch Headlines Use Case
protocol FetchHeadlinesUseCaseProtocol {
    func execute(category: NewsCategory, page: Int) -> AnyPublisher<PaginatedArticles, AppError>
}

final class FetchHeadlinesUseCase: FetchHeadlinesUseCaseProtocol {
    private let newsRepository: NewsRepositoryProtocol
    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let pageSize: Int = 20

    init(newsRepository: NewsRepositoryProtocol, bookmarkRepository: BookmarkRepositoryProtocol) {
        self.newsRepository = newsRepository
        self.bookmarkRepository = bookmarkRepository
    }

    func execute(category: NewsCategory, page: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        newsRepository
            .fetchTopHeadlines(category: category, page: page, pageSize: pageSize)
            .map { [weak self] paginated in
                guard let self else { return paginated }
                let enriched = paginated.articles.map { article in
                    var a = article
                    a.isBookmarked = self.bookmarkRepository.isBookmarkedSync(id: article.id)
                    return a
                }
                return PaginatedArticles(articles: enriched, totalResults: paginated.totalResults,
                                        currentPage: paginated.currentPage, pageSize: paginated.pageSize)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Search Articles Use Case
protocol SearchArticlesUseCaseProtocol {
    func execute(query: String, page: Int) -> AnyPublisher<PaginatedArticles, AppError>
}

final class SearchArticlesUseCase: SearchArticlesUseCaseProtocol {
    private let newsRepository: NewsRepositoryProtocol
    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let pageSize: Int = 20

    init(newsRepository: NewsRepositoryProtocol, bookmarkRepository: BookmarkRepositoryProtocol) {
        self.newsRepository = newsRepository
        self.bookmarkRepository = bookmarkRepository
    }

    func execute(query: String, page: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return Fail(error: AppError.noResults).eraseToAnyPublisher()
        }
        return newsRepository
            .searchArticles(query: query, page: page, pageSize: pageSize)
            .map { [weak self] paginated in
                guard let self else { return paginated }
                let enriched = paginated.articles.map { article in
                    var a = article
                    a.isBookmarked = self.bookmarkRepository.isBookmarkedSync(id: article.id)
                    return a
                }
                return PaginatedArticles(articles: enriched, totalResults: paginated.totalResults,
                                        currentPage: paginated.currentPage, pageSize: paginated.pageSize)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Bookmark Use Case
protocol BookmarkUseCaseProtocol {
    func fetchBookmarks() -> AnyPublisher<[Article], AppError>
    func toggleBookmark(_ article: Article) -> AnyPublisher<Bool, AppError>
}

final class BookmarkUseCase: BookmarkUseCaseProtocol {
    private let bookmarkRepository: BookmarkRepositoryProtocol

    init(bookmarkRepository: BookmarkRepositoryProtocol) {
        self.bookmarkRepository = bookmarkRepository
    }

    func fetchBookmarks() -> AnyPublisher<[Article], AppError> {
        bookmarkRepository.fetchBookmarks()
    }

    func toggleBookmark(_ article: Article) -> AnyPublisher<Bool, AppError> {
        if bookmarkRepository.isBookmarkedSync(id: article.id) {
            return bookmarkRepository.removeBookmark(id: article.id)
                .map { _ in false }
                .eraseToAnyPublisher()
        } else {
            return bookmarkRepository.saveBookmark(article)
                .map { _ in true }
                .eraseToAnyPublisher()
        }
    }
}