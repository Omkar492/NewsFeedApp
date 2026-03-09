//
//  ArticleCacheStore.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//

import Foundation

final class ArticleCacheStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let cacheDirectory: URL

    convenience init(fileManager: FileManager = .default) {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.init(cacheDirectory: baseDirectory.appendingPathComponent("ArticleCache", isDirectory: true),
                  fileManager: fileManager)
    }

    init(cacheDirectory: URL, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        self.cacheDirectory = cacheDirectory

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
        }
    }

    func save(_ articles: PaginatedArticles, for key: String) {
        let url = fileURL(for: key)
        guard let data = try? encoder.encode(articles) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func save(_ articles: [Article], for key: String) {
        let url = fileURL(for: key)
        guard let data = try? encoder.encode(articles) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func loadPaginatedArticles(for key: String) -> PaginatedArticles? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(PaginatedArticles.self, from: data)
    }

    func loadArticles(for key: String) -> [Article]? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([Article].self, from: data)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return cacheDirectory.appendingPathComponent("\(safeKey).json")
    }
}
