//
//  MockArticle.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 09/03/26.
//


import Foundation
import Combine
@testable import NewsFeedApp

// MARK: - Mock Article Factory
struct MockArticle {
    static func make(
        id: String = "test-id-1",
        title: String = "Test Article Title",
        description: String? = "Test description",
        sourceName: String = "Test Source",
        publishedAt: Date = Date(),
        imageURL: URL? = URL(string: "https://example.com/image.jpg"),
        url: URL? = URL(string: "https://example.com/article"),
        category: NewsCategory? = .technology,
        isBookmarked: Bool = false
    ) -> Article {
        Article(
            id: id,
            title: title,
            description: description,
            content: "Full article content...",
            author: "Test Author",
            sourceName: sourceName,
            sourceURL: url,
            imageURL: imageURL,
            publishedAt: publishedAt,
            url: url,
            category: category,
            isBookmarked: isBookmarked
        )
    }

    static func makeList(count: Int) -> [Article] {
        (0..<count).map { make(id: "test-id-\($0)", title: "Article \($0)") }
    }

    static func makePaginated(articles: [Article] = makeList(count: 10), total: Int = 50, page: Int = 1) -> PaginatedArticles {
        PaginatedArticles(articles: articles, totalResults: total, currentPage: page, pageSize: 20)
    }
}

// MARK: - Mock News Repository
@MainActor
final class MockNewsRepository: NewsRepositoryProtocol {
    var fetchHeadlinesResult: Result<PaginatedArticles, AppError> = .success(MockArticle.makePaginated())
    var searchResult: Result<PaginatedArticles, AppError> = .success(MockArticle.makePaginated())
    var trendingResult: Result<[Article], AppError> = .success(MockArticle.makeList(count: 5))

    var fetchHeadlinesCallCount = 0
    var searchCallCount = 0
    var lastSearchQuery: String?
    var lastCategory: NewsCategory?

    func fetchTopHeadlines(category: NewsCategory, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        fetchHeadlinesCallCount += 1
        lastCategory = category
        return fetchHeadlinesResult.publisher.eraseToAnyPublisher()
    }

    func searchArticles(query: String, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        searchCallCount += 1
        lastSearchQuery = query
        return searchResult.publisher.eraseToAnyPublisher()
    }

    func fetchTrending() -> AnyPublisher<[Article], AppError> {
        trendingResult.publisher.eraseToAnyPublisher()
    }
}

// MARK: - Mock Bookmark Repository
@MainActor
final class MockBookmarkRepository: BookmarkRepositoryProtocol {
    var bookmarks: [Article] = []
    var bookmarkedIDs: Set<String> = []
    var saveCallCount = 0
    var removeCallCount = 0
    var fetchBookmarksCallCount = 0

    func fetchBookmarks() -> AnyPublisher<[Article], AppError> {
        fetchBookmarksCallCount += 1
        return Just(bookmarks).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    func saveBookmark(_ article: Article) -> AnyPublisher<Void, AppError> {
        saveCallCount += 1
        bookmarkedIDs.insert(article.id)
        bookmarks.append(article)
        return Just(()).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    func removeBookmark(id: String) -> AnyPublisher<Void, AppError> {
        removeCallCount += 1
        bookmarkedIDs.remove(id)
        bookmarks.removeAll { $0.id == id }
        return Just(()).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    func isBookmarked(id: String) -> AnyPublisher<Bool, AppError> {
        Just(bookmarkedIDs.contains(id)).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    func isBookmarkedSync(id: String) -> Bool {
        bookmarkedIDs.contains(id)
    }
}

// MARK: - Mock API Client
@MainActor
final class MockAPIClient: APIClientProtocol {
    var responseData: Data = Data()
    var shouldFail = false
    var error: AppError = .networkUnavailable
    var requestCount = 0

    func perform<R: APIRequest>(_ request: R) -> AnyPublisher<R.Response, AppError> {
        requestCount += 1
        if shouldFail {
            return Fail(error: error).eraseToAnyPublisher()
        }
        guard let response = try? JSONDecoder().decode(R.Response.self, from: responseData) else {
            return Fail(error: .decodingFailed).eraseToAnyPublisher()
        }
        return Just(response).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }
}

// MARK: - Mock Use Cases
@MainActor
final class MockFetchHeadlinesUseCase: FetchHeadlinesUseCaseProtocol {
    var result: Result<PaginatedArticles, AppError> = .success(MockArticle.makePaginated())
    var callCount = 0

    func execute(category: NewsCategory, page: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        callCount += 1
        return result.publisher.eraseToAnyPublisher()
    }
}

@MainActor
final class MockSearchUseCase: SearchArticlesUseCaseProtocol {
    var result: Result<PaginatedArticles, AppError> = .success(MockArticle.makePaginated())
    var lastQuery: String?
    var callCount = 0

    func execute(query: String, page: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        callCount += 1
        lastQuery = query
        return result.publisher.eraseToAnyPublisher()
    }
}

@MainActor
final class MockBookmarkUseCase: BookmarkUseCaseProtocol {
    var bookmarksResult: Result<[Article], AppError> = .success([])
    var toggleResult: Result<Bool, AppError> = .success(true)
    var toggleCallCount = 0
    var fetchBookmarksCallCount = 0

    func fetchBookmarks() -> AnyPublisher<[Article], AppError> {
        fetchBookmarksCallCount += 1
        return bookmarksResult.publisher.eraseToAnyPublisher()
    }

    func toggleBookmark(_ article: Article) -> AnyPublisher<Bool, AppError> {
        toggleCallCount += 1
        return toggleResult.publisher.eraseToAnyPublisher()
    }
}
