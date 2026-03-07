//
//  HTTPMethod.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import Combine

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

// MARK: - API Request Protocol
protocol APIRequest {
    associatedtype Response: Decodable
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
}

extension APIRequest {
    var method: HTTPMethod { .GET }
    var headers: [String: String]? { nil }

    func buildURLRequest() throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        guard let url = components?.url else { throw AppError.invalidURL }
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func perform<R: APIRequest>(_ request: R) -> AnyPublisher<R.Response, AppError>
}

// MARK: - URLSession API Client
final class URLSessionAPIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func perform<R: APIRequest>(_ request: R) -> AnyPublisher<R.Response, AppError> {
        guard let urlRequest = try? request.buildURLRequest() else {
            return Fail(error: AppError.invalidURL).eraseToAnyPublisher()
        }

        logRequest(urlRequest)

        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response -> R.Response in
                guard let self else { throw AppError.unknown("Client deallocated") }
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.unknown("Invalid response")
                }
                self.logResponse(data: data, response: httpResponse)
                switch httpResponse.statusCode {
                case 200...299:
                    return try self.decoder.decode(R.Response.self, from: data)
                case 401:
                    throw AppError.apiKeyMissing
                case 429:
                    throw AppError.rateLimited
                case 500...599:
                    throw AppError.serverError(statusCode: httpResponse.statusCode)
                default:
                    throw AppError.serverError(statusCode: httpResponse.statusCode)
                }
            }
            .mapError { error -> AppError in
                if let appError = error as? AppError { return appError }
                let nsError = error as NSError
                if nsError.code == NSURLErrorNotConnectedToInternet ||
                   nsError.code == NSURLErrorNetworkConnectionLost {
                    return .networkUnavailable
                }
                if error is DecodingError { return .decodingFailed }
                return .unknown(error.localizedDescription)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "UNKNOWN"
        let urlString = sanitizedURLString(for: request.url)
        let headerLines = (request.allHTTPHeaderFields ?? [:])
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
        let body = formattedBody(from: request.httpBody) ?? "None"

        print("""

        ===== API Request =====
        \(method) \(urlString)
        Headers:
        \(headerLines.isEmpty ? "None" : headerLines)
        Body:
        \(body)
        =======================
        """)
        #endif
    }

    private func logResponse(data: Data, response: HTTPURLResponse) {
        #if DEBUG
        let urlString = sanitizedURLString(for: response.url)
        let headerLines = response.allHeaderFields
            .map { "\($0.key): \($0.value)" }
            .sorted()
            .joined(separator: "\n")
        let body = formattedBody(from: data) ?? "Empty"

        print("""

        ===== API Response =====
        Status: \(response.statusCode)
        URL: \(urlString)
        Headers:
        \(headerLines.isEmpty ? "None" : headerLines)
        Body:
        \(body)
        ========================
        """)
        #endif
    }

    private func sanitizedURLString(for url: URL?) -> String {
        guard
            let url,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return "Invalid URL"
        }

        components.queryItems = components.queryItems?.map { item in
            item.name.lowercased() == "apikey"
                ? URLQueryItem(name: item.name, value: "<redacted>")
                : item
        }

        return components.string ?? url.absoluteString
    }

    private func formattedBody(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
            let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }

        return String(data: data, encoding: .utf8) ?? "<non-text body: \(data.count) bytes>"
    }
}
