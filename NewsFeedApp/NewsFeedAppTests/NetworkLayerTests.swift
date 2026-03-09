//
//  NetworkLayerTests.swift
//  NewsFeedAppTests
//
//  Created by Omkar Chougule on 09/03/26.
//

import XCTest
import Combine
@testable import NewsFeedApp

@MainActor
final class NetworkLayerTests: XCTestCase {
    private var mockAPIClient: MockAPIClient!
    private var newsRepository: NewsRepository!
    private var articleCacheStore: ArticleCacheStore!
    private var cacheDirectory: URL!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        cacheDirectory = makeTemporaryDirectory()
        articleCacheStore = ArticleCacheStore(cacheDirectory: cacheDirectory)
        newsRepository = NewsRepository(apiClient: mockAPIClient, articleCacheStore: articleCacheStore)
    }

    override func tearDown() {
        newsRepository = nil
        articleCacheStore = nil
        mockAPIClient = nil
        if let cacheDirectory {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
        cacheDirectory = nil
        super.tearDown()
    }

    func testTopHeadlinesRequestBuildsExpectedURLRequest() throws {
        let request = TopHeadlinesRequest(category: .technology,
                                          page: 2,
                                          pageSize: AppConstants.Network.defaultPageSize)

        let urlRequest = try request.buildURLRequest()
        let components = URLComponents(url: try XCTUnwrap(urlRequest.url), resolvingAgainstBaseURL: false)
        let queryItems = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(components?.path, "/v2/top-headlines")
        XCTAssertEqual(queryItems["country"], AppConstants.Network.country)
        XCTAssertEqual(queryItems["category"], "technology")
        XCTAssertEqual(queryItems["page"], "2")
        XCTAssertEqual(queryItems["pageSize"], "\(AppConstants.Network.defaultPageSize)")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testFetchTopHeadlinesMapsResponseIntoPaginatedArticles() throws {
        mockAPIClient.responseData = makeAPIResponse(articleCount: 3, totalResults: 12)

        let result = try awaitPublisher(newsRepository.fetchTopHeadlines(category: .technology, page: 1, pageSize: 20))

        XCTAssertEqual(result.articles.count, 3)
        XCTAssertEqual(result.totalResults, 12)
        XCTAssertEqual(result.currentPage, 1)
    }

    func testSearchArticlesReturnsNoResultsForEmptyMappedArticles() {
        let response: [String: Any] = ["status": "ok", "totalResults": 0, "articles": []]
        mockAPIClient.responseData = try! JSONSerialization.data(withJSONObject: response)

        XCTAssertThrowsError(try awaitPublisher(newsRepository.searchArticles(query: "nothing", page: 1, pageSize: 20))) { error in
            XCTAssertEqual(error as? AppError, .noResults)
        }
    }

    func testFetchTopHeadlinesReturnsCachedArticlesWhenOffline() throws {
        let cached = MockArticle.makePaginated(articles: MockArticle.makeList(count: 2), total: 2)
        articleCacheStore.save(cached, for: "top-headlines|general|1|20")
        mockAPIClient.shouldFail = true
        mockAPIClient.error = .networkUnavailable

        let result = try awaitPublisher(newsRepository.fetchTopHeadlines(category: .general, page: 1, pageSize: 20))

        XCTAssertEqual(result.articles, cached.articles)
    }

    func testSuccessfulSearchCachesResults() throws {
        mockAPIClient.responseData = makeAPIResponse(articleCount: 2, totalResults: 2)

        _ = try awaitPublisher(newsRepository.searchArticles(query: "swift", page: 1, pageSize: 20))
        let cached = articleCacheStore.loadPaginatedArticles(for: "search|swift|1|20")

        XCTAssertEqual(cached?.articles.count, 2)
        XCTAssertEqual(cached?.currentPage, 1)
    }

    func testRemovedArticlesAreFilteredOutDuringMapping() throws {
        let response: [String: Any] = [
            "status": "ok",
            "totalResults": 2,
            "articles": [
                [
                    "title": "[Removed]",
                    "url": "https://example.com/removed",
                    "publishedAt": "2024-01-01T12:00:00Z",
                    "source": ["name": "Source"]
                ],
                [
                    "title": "Valid",
                    "url": "https://example.com/valid",
                    "publishedAt": "2024-01-01T12:00:00Z",
                    "source": ["name": "Source"]
                ]
            ]
        ]
        mockAPIClient.responseData = try! JSONSerialization.data(withJSONObject: response)

        let result = try awaitPublisher(newsRepository.fetchTopHeadlines(category: .general, page: 1, pageSize: 20))

        XCTAssertEqual(result.articles.map(\.title), ["Valid"])
    }

    private func makeAPIResponse(articleCount: Int, totalResults: Int) -> Data {
        let articles = (0..<articleCount).map { index -> [String: Any] in
            [
                "title": "Article \(index)",
                "description": "Description \(index)",
                "content": "Content \(index)",
                "author": "Author \(index)",
                "url": "https://example.com/article\(index)",
                "urlToImage": "https://example.com/image\(index).jpg",
                "publishedAt": "2024-01-01T12:00:00Z",
                "source": ["id": "source-\(index)", "name": "Source \(index)"]
            ]
        }

        let response: [String: Any] = [
            "status": "ok",
            "totalResults": totalResults,
            "articles": articles
        ]

        return try! JSONSerialization.data(withJSONObject: response)
    }
}
