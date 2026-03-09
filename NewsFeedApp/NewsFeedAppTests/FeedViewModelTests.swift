//
//  FeedViewModelTests.swift
//  NewsFeedAppTests
//
//  Created by Omkar Chougule on 09/03/26.
//

import XCTest
import Combine
@testable import NewsFeedApp

@MainActor
final class FeedViewModelTests: XCTestCase {
    private var sut: FeedViewModel!
    private var mockHeadlinesUseCase: MockFetchHeadlinesUseCase!
    private var mockBookmarkUseCase: MockBookmarkUseCase!

    override func setUp() {
        super.setUp()
        mockHeadlinesUseCase = MockFetchHeadlinesUseCase()
        mockBookmarkUseCase = MockBookmarkUseCase()
        sut = FeedViewModel(fetchHeadlinesUseCase: mockHeadlinesUseCase,
                            bookmarkUseCase: mockBookmarkUseCase)
    }

    override func tearDown() {
        sut = nil
        mockBookmarkUseCase = nil
        mockHeadlinesUseCase = nil
        super.tearDown()
    }

    func testViewDidLoadLoadsArticlesAndSetsLoadedState() {
        let articles = MockArticle.makeList(count: 3)
        mockHeadlinesUseCase.result = .success(MockArticle.makePaginated(articles: articles, total: 3))

        sut.viewDidLoad()

        XCTAssertEqual(sut.articles, articles)
        XCTAssertEqual(mockHeadlinesUseCase.callCount, 1)
        if case .loaded(let loadedArticles) = sut.state {
            XCTAssertEqual(loadedArticles, articles)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testViewDidLoadWhenUseCaseFailsSetsErrorState() {
        mockHeadlinesUseCase.result = .failure(.networkUnavailable)

        sut.viewDidLoad()

        if case .error(let error) = sut.state {
            XCTAssertEqual(error, .networkUnavailable)
        } else {
            XCTFail("Expected error state")
        }
    }

    func testViewDidLoadWithEmptyArticlesSetsEmptyState() {
        mockHeadlinesUseCase.result = .success(MockArticle.makePaginated(articles: [], total: 0))

        sut.viewDidLoad()

        if case .empty = sut.state {
            XCTAssertTrue(sut.articles.isEmpty)
        } else {
            XCTFail("Expected empty state")
        }
    }

    func testSelectCategoryUpdatesCategoryAndRefetches() {
        mockHeadlinesUseCase.result = .success(MockArticle.makePaginated())

        sut.selectCategory(.sports)

        XCTAssertEqual(sut.selectedCategory, .sports)
        XCTAssertEqual(mockHeadlinesUseCase.callCount, 1)
    }

    func testSelectingSameCategoryDoesNotRefetch() {
        mockHeadlinesUseCase.result = .success(MockArticle.makePaginated())

        sut.selectCategory(.general)

        XCTAssertEqual(mockHeadlinesUseCase.callCount, 0)
    }

    func testRefreshTriggersSecondFetch() {
        mockHeadlinesUseCase.result = .success(MockArticle.makePaginated())
        sut.viewDidLoad()

        sut.refresh()

        XCTAssertEqual(mockHeadlinesUseCase.callCount, 2)
    }

    func testToggleBookmarkCallsUseCase() {
        let article = MockArticle.make()

        sut.toggleBookmark(article)

        XCTAssertEqual(mockBookmarkUseCase.toggleCallCount, 1)
    }
}

@MainActor
final class SearchViewModelTests: XCTestCase {
    private var sut: SearchViewModel!
    private var mockSearchUseCase: MockSearchUseCase!
    private var mockBookmarkUseCase: MockBookmarkUseCase!

    override func setUp() {
        super.setUp()
        mockSearchUseCase = MockSearchUseCase()
        mockBookmarkUseCase = MockBookmarkUseCase()
        sut = SearchViewModel(searchUseCase: mockSearchUseCase,
                              bookmarkUseCase: mockBookmarkUseCase)
    }

    override func tearDown() {
        sut = nil
        mockBookmarkUseCase = nil
        mockSearchUseCase = nil
        super.tearDown()
    }

    func testBlankQueryKeepsIdleState() throws {
        sut.searchQuerySubject.send("   ")
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))

        if case .idle = sut.state {
            XCTAssertTrue(sut.articles.isEmpty)
        } else {
            XCTFail("Expected idle state")
        }
    }

    func testSearchPublishesLoadedArticlesAfterDebounce() {
        mockSearchUseCase.result = .success(MockArticle.makePaginated(articles: MockArticle.makeList(count: 2), total: 2))

        sut.searchQuerySubject.send("swift")
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))

        XCTAssertEqual(mockSearchUseCase.callCount, 1)
        XCTAssertEqual(mockSearchUseCase.lastQuery, "swift")
        XCTAssertEqual(sut.articles.count, 2)
        if case .loaded(let articles) = sut.state {
            XCTAssertEqual(articles.count, 2)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testClearSearchResetsArticlesAndState() {
        sut.clearSearch()

        XCTAssertTrue(sut.articles.isEmpty)
        if case .idle = sut.state {
        } else {
            XCTFail("Expected idle state")
        }
    }

    func testToggleBookmarkCallsUseCase() {
        let article = MockArticle.make()

        sut.toggleBookmark(article)

        XCTAssertEqual(mockBookmarkUseCase.toggleCallCount, 1)
    }
}

@MainActor
final class BookmarksViewModelTests: XCTestCase {
    private var sut: BookmarksViewModel!
    private var mockBookmarkUseCase: MockBookmarkUseCase!

    override func setUp() {
        super.setUp()
        mockBookmarkUseCase = MockBookmarkUseCase()
        sut = BookmarksViewModel(bookmarkUseCase: mockBookmarkUseCase)
    }

    override func tearDown() {
        sut = nil
        mockBookmarkUseCase = nil
        super.tearDown()
    }

    func testViewDidAppearLoadsBookmarks() throws {
        let articles = MockArticle.makeList(count: 2)
        mockBookmarkUseCase.bookmarksResult = .success(articles)

        sut.viewDidAppear()

        XCTAssertEqual(mockBookmarkUseCase.fetchBookmarksCallCount, 1)
        XCTAssertEqual(sut.articles, articles)
        if case .loaded(let loadedArticles) = sut.state {
            XCTAssertEqual(loadedArticles, articles)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testViewDidAppearWithNoBookmarksSetsEmptyState() {
        mockBookmarkUseCase.bookmarksResult = .success([])

        sut.viewDidAppear()

        if case .empty = sut.state {
            XCTAssertTrue(sut.articles.isEmpty)
        } else {
            XCTFail("Expected empty state")
        }
    }

    func testRemoveBookmarkUpdatesArticlesList() {
        let articles = MockArticle.makeList(count: 2)
        mockBookmarkUseCase.bookmarksResult = .success(articles)
        mockBookmarkUseCase.toggleResult = .success(false)
        sut.viewDidAppear()

        sut.removeBookmark(articles[0])

        XCTAssertEqual(mockBookmarkUseCase.toggleCallCount, 1)
        XCTAssertEqual(sut.articles.map(\.id), [articles[1].id])
    }
}
