//
//  NewsAPIConfig.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation

// MARK: - NewsAPI Configuration
enum NewsAPIConfig {
    // Replace with your actual NewsAPI.org key
    // Get a free key at: https://newsapi.org/register
    static let apiKey: String = {
        // Load from Info.plist for security
        Bundle.main.object(forInfoDictionaryKey: "NEWS_API_KEY") as? String ?? "YOUR_API_KEY_HERE"
    }()
    static let baseURL = URL(string: "https://newsapi.org/v2")!
}

// MARK: - Top Headlines Request
struct TopHeadlinesRequest: APIRequest {
    typealias Response = NewsAPIResponse

    let category: NewsCategory
    let page: Int
    let pageSize: Int

    var baseURL: URL { NewsAPIConfig.baseURL }
    var path: String { "/top-headlines" }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "apiKey", value: NewsAPIConfig.apiKey),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "category", value: category.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
    }
}

// MARK: - Search Request
struct SearchArticlesRequest: APIRequest {
    typealias Response = NewsAPIResponse

    let query: String
    let page: Int
    let pageSize: Int

    var baseURL: URL { NewsAPIConfig.baseURL }
    var path: String { "/everything" }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "apiKey", value: NewsAPIConfig.apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
    }
}

// MARK: - NewsAPI Response DTOs
struct NewsAPIResponse: Decodable {
    let status: String
    let totalResults: Int?
    let articles: [ArticleDTO]?
    let code: String?
    let message: String?
}

struct ArticleDTO: Decodable {
    let title: String?
    let description: String?
    let content: String?
    let author: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: String?
    let source: SourceDTO?
}

struct SourceDTO: Decodable {
    let id: String?
    let name: String?
}

// MARK: - DTO → Domain Mapping
extension ArticleDTO {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601FormatterBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func toDomain(category: NewsCategory? = nil) -> Article? {
        guard
            let title = title, !title.isEmpty, title != "[Removed]",
            let urlStr = url, let articleURL = URL(string: urlStr)
        else { return nil }

        let publishDate = ArticleDTO.iso8601Formatter.date(from: publishedAt ?? "")
            ?? ArticleDTO.iso8601FormatterBasic.date(from: publishedAt ?? "")
            ?? Date()

        let imageURL = urlToImage.flatMap { URL(string: $0) }
        let sourceURL = URL(string: urlStr)

        // Create stable ID from URL
        let id = urlStr.data(using: .utf8)?.base64EncodedString() ?? urlStr

        return Article(
            id: id,
            title: title,
            description: description,
            content: content,
            author: author,
            sourceName: source?.name ?? "Unknown",
            sourceURL: sourceURL,
            imageURL: imageURL,
            publishedAt: publishDate,
            url: articleURL,
            category: category
        )
    }
}