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

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchTopHeadlines(category: NewsCategory, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        let request = TopHeadlinesRequest(category: category, page: page, pageSize: pageSize)
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
            .mapError { error -> AppError in
                (error as? AppError) ?? .unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    func searchArticles(query: String, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError> {
        let request = SearchArticlesRequest(query: query, page: page, pageSize: pageSize)
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
            .mapError { error -> AppError in
                (error as? AppError) ?? .unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    func fetchTrending() -> AnyPublisher<[Article], AppError> {
        let request = TopHeadlinesRequest(category: .general, page: 1, pageSize: 5)
        return apiClient.perform(request)
            .map { response in
                (response.articles ?? []).compactMap { $0.toDomain(category: .general) }
            }
            .eraseToAnyPublisher()
    }
}