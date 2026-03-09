//
//  NewsFeedAppTests.swift
//  NewsFeedAppTests
//
//  Created by Omkar Chougule on 09/03/26.
//

import XCTest
@testable import NewsFeedApp

@MainActor
final class NewsFeedAppTests: XCTestCase {
    private var cacheDirectory: URL!
    private var cacheStore: ArticleCacheStore!

    override func setUp() {
        super.setUp()
        cacheDirectory = makeTemporaryDirectory()
        cacheStore = ArticleCacheStore(cacheDirectory: cacheDirectory)
    }

    override func tearDown() {
        cacheStore = nil
        if let cacheDirectory {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
        cacheDirectory = nil
        super.tearDown()
    }

    func testArticleCacheStorePersistsPaginatedArticles() {
        let paginated = MockArticle.makePaginated(articles: MockArticle.makeList(count: 2), total: 2)

        cacheStore.save(paginated, for: "headlines")
        let cached = cacheStore.loadPaginatedArticles(for: "headlines")

        XCTAssertEqual(cached?.articles, paginated.articles)
        XCTAssertEqual(cached?.totalResults, paginated.totalResults)
        XCTAssertEqual(cached?.currentPage, paginated.currentPage)
        XCTAssertEqual(cached?.pageSize, paginated.pageSize)
    }

    func testArticleCacheStorePersistsTrendingArticles() {
        let articles = MockArticle.makeList(count: 3)

        cacheStore.save(articles, for: "trending")
        let cached = cacheStore.loadArticles(for: "trending")

        XCTAssertEqual(cached, articles)
    }

    func testArticleDTOToDomainBuildsStableArticle() {
        let dto = ArticleDTO(
            title: "Breaking News",
            description: "Description",
            content: "Content",
            author: "Author",
            url: "https://example.com/story",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "2026-03-09T10:00:00Z",
            source: SourceDTO(id: "source-id", name: "Example")
        )

        let article = dto.toDomain(category: .science)

        XCTAssertEqual(article?.title, "Breaking News")
        XCTAssertEqual(article?.sourceName, "Example")
        XCTAssertEqual(article?.category, .science)
        XCTAssertEqual(article?.id, Data("https://example.com/story".utf8).base64EncodedString())
    }

    func testArticleDTOToDomainFiltersRemovedTitle() {
        let dto = ArticleDTO(
            title: "[Removed]",
            description: nil,
            content: nil,
            author: nil,
            url: "https://example.com/story",
            urlToImage: nil,
            publishedAt: "2026-03-09T10:00:00Z",
            source: SourceDTO(id: nil, name: "Example")
        )

        XCTAssertNil(dto.toDomain())
    }
}
