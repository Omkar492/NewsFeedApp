//
//  NewsRepositoryProtocol.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - News Repository Protocol
protocol NewsRepositoryProtocol {
    func fetchTopHeadlines(category: NewsCategory, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError>
    func searchArticles(query: String, page: Int, pageSize: Int) -> AnyPublisher<PaginatedArticles, AppError>
    func fetchTrending() -> AnyPublisher<[Article], AppError>
}

// MARK: - Bookmark Repository Protocol
protocol BookmarkRepositoryProtocol {
    func fetchBookmarks() -> AnyPublisher<[Article], AppError>
    func saveBookmark(_ article: Article) -> AnyPublisher<Void, AppError>
    func removeBookmark(id: String) -> AnyPublisher<Void, AppError>
    func isBookmarked(id: String) -> AnyPublisher<Bool, AppError>
    func isBookmarkedSync(id: String) -> Bool
}