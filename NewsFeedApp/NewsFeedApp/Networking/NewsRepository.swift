//
//  NewsRepository.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - News Repository Implementation
final class NewsRepository: NewsRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let articleCacheStore: ArticleCacheStore

    init(apiClient: APIClientProtocol, articleCacheStore: ArticleCacheStore) {
        self.apiClient = apiClient
        self.articleCacheStore = articleCacheStore
    }

    func fetchTopHeadlines(category: NewsCategory, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        let request = TopHeadlinesRequest(category: category, page: page, pageSize: pageSize)
        let cacheKey = CacheKey.topHeadlines(category: category, page: page, pageSize: pageSize).rawValue
        return apiClient.perform(request)
            .tryMap { response -> PaginatedArticles in
                if let code = response.code {
                    switch code {
                    case "apiKeyInvalid", "apiKeyDisabled", "apiKeyExhausted":
                        throw AppError.apiKeyMissing
                    case "rateLimited":
                        throw AppError.rateLimited
                    default:
                        throw AppError.unknown(response.message ?? code)
                    }
                }
                let articles = (response.articles ?? []).compactMap { $0.toDomain(category: category) }
                return PaginatedArticles(
                    articles: articles,
                    totalResults: response.totalResults ?? 0,
                    currentPage: page,
                    pageSize: pageSize
                )
            }
            .handleEvents(receiveOutput: { [articleCacheStore] paginated in
                articleCacheStore.save(paginated, for: cacheKey)
            })
            .mapError { error -> AppError in
                (error as? AppError) ?? .unknown(error.localizedDescription)
            }
            .catch { [articleCacheStore] error -> AnyPublisher<PaginatedArticles, AppError> in
                guard error == .networkUnavailable,
                      let cached = articleCacheStore.loadPaginatedArticles(for: cacheKey) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                return Just(cached)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func searchArticles(query: String, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        let request = SearchArticlesRequest(query: query, page: page, pageSize: pageSize)
        let cacheKey = CacheKey.search(query: query, page: page, pageSize: pageSize).rawValue
        return apiClient.perform(request)
            .tryMap { response -> PaginatedArticles in
                if let code = response.code {
                    throw AppError.unknown(response.message ?? code)
                }
                let articles = (response.articles ?? []).compactMap { $0.toDomain() }
                if articles.isEmpty && page == 1 { throw AppError.noResults }
                return PaginatedArticles(
                    articles: articles,
                    totalResults: response.totalResults ?? 0,
                    currentPage: page,
                    pageSize: pageSize
                )
            }
            .handleEvents(receiveOutput: { [articleCacheStore] paginated in
                articleCacheStore.save(paginated, for: cacheKey)
            })
            .mapError { error -> AppError in
                (error as? AppError) ?? .unknown(error.localizedDescription)
            }
            .catch { [articleCacheStore] error -> AnyPublisher<PaginatedArticles, AppError> in
                guard error == .networkUnavailable,
                      let cached = articleCacheStore.loadPaginatedArticles(for: cacheKey) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                return Just(cached)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func fetchTrending() -> AnyPublisher<[Article], AppError> {
        let request = TopHeadlinesRequest(category: .general, page: 1, pageSize: 5)
        let cacheKey = CacheKey.trending.rawValue
        return apiClient.perform(request)
            .map { response in
                (response.articles ?? []).compactMap { $0.toDomain(category: .general) }
            }
            .handleEvents(receiveOutput: { [articleCacheStore] articles in
                articleCacheStore.save(articles, for: cacheKey)
            })
            .catch { [articleCacheStore] error -> AnyPublisher<[Article], AppError> in
                guard error == .networkUnavailable,
                      let cached = articleCacheStore.loadArticles(for: cacheKey) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                return Just(cached)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

private enum CacheKey {
    case topHeadlines(category: NewsCategory, page: Int, pageSize: Int)
    case search(query: String, page: Int, pageSize: Int)
    case trending

    var rawValue: String {
        switch self {
        case .topHeadlines(let category, let page, let pageSize):
            return "top-headlines|\(category.rawValue)|\(page)|\(pageSize)"
        case .search(let query, let page, let pageSize):
            return "search|\(query.lowercased())|\(page)|\(pageSize)"
        case .trending:
            return "trending"
        }
    }
}
