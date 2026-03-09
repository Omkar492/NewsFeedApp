//
//  Article.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation

// MARK: - Article Domain Model

nonisolated struct Article: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let title: String
    let description: String?
    let content: String?
    let author: String?
    let sourceName: String
    let sourceURL: URL?
    let imageURL: URL?
    let publishedAt: Date
    let url: URL?
    let category: NewsCategory?
    var isBookmarked: Bool = false

    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - News Category
nonisolated enum NewsCategory: String, CaseIterable, Identifiable, Sendable, Codable {
    case general = "general"
    case business = "business"
    case technology = "technology"
    case entertainment = "entertainment"
    case sports = "sports"
    case science = "science"
    case health = "health"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general:       return "Top Stories"
        case .business:      return "Business"
        case .technology:    return "Technology"
        case .entertainment: return "Entertainment"
        case .sports:        return "Sports"
        case .science:       return "Science"
        case .health:        return "Health"
        }
    }

    var systemIconName: String {
        switch self {
        case .general:       return "newspaper"
        case .business:      return "chart.bar"
        case .technology:    return "cpu"
        case .entertainment: return "film"
        case .sports:        return "sportscourt"
        case .science:       return "flask"
        case .health:        return "heart.circle"
        }
    }
}

// MARK: - Pagination
nonisolated struct PaginatedArticles: Sendable, Codable {
    let articles: [Article]
    let totalResults: Int
    let currentPage: Int
    let pageSize: Int

    var hasNextPage: Bool {
        currentPage * pageSize < totalResults
    }
}
