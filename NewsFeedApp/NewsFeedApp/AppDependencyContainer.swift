//
//  AppDependencyContainer.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation

// MARK: - Dependency Container
final class AppDependencyContainer {
    static let shared = AppDependencyContainer()

    // MARK: - Core
    private lazy var apiClient: APIClientProtocol = URLSessionAPIClient()
    private lazy var coreDataStack: CoreDataStack = .shared

    // MARK: - Repositories
    lazy var newsRepository: NewsRepositoryProtocol = NewsRepository(apiClient: apiClient)
    lazy var bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository(coreDataStack: coreDataStack)

    // MARK: - Use Cases
    func makeFetchHeadlinesUseCase() -> FetchHeadlinesUseCaseProtocol {
        FetchHeadlinesUseCase(newsRepository: newsRepository, bookmarkRepository: bookmarkRepository)
    }

    func makeSearchArticlesUseCase() -> SearchArticlesUseCaseProtocol {
        SearchArticlesUseCase(newsRepository: newsRepository, bookmarkRepository: bookmarkRepository)
    }

    func makeBookmarkUseCase() -> BookmarkUseCaseProtocol {
        BookmarkUseCase(bookmarkRepository: bookmarkRepository)
    }

    // MARK: - ViewModels
    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            fetchHeadlinesUseCase: makeFetchHeadlinesUseCase(),
            bookmarkUseCase: makeBookmarkUseCase()
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            searchUseCase: makeSearchArticlesUseCase(),
            bookmarkUseCase: makeBookmarkUseCase()
        )
    }

    func makeBookmarksViewModel() -> BookmarksViewModel {
        BookmarksViewModel(bookmarkUseCase: makeBookmarkUseCase())
    }

    func makeDetailViewModel(article: Article) -> DetailViewModel {
        DetailViewModel(article: article, bookmarkUseCase: makeBookmarkUseCase())
    }

    private init() {}
}