//
//  AppError.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation

// MARK: - App Error
enum AppError: LocalizedError, Equatable {
    case networkUnavailable
    case serverError(statusCode: Int)
    case decodingFailed
    case invalidURL
    case apiKeyMissing
    case rateLimited
    case noResults
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .serverError(let code):
            return "Server error occurred (code: \(code)). Please try again later."
        case .decodingFailed:
            return "Unable to process server response."
        case .invalidURL:
            return "Invalid request URL."
        case .apiKeyMissing:
            return "API configuration error. Please contact support."
        case .rateLimited:
            return "Too many requests. Please wait a moment before trying again."
        case .noResults:
            return "No articles found for your request."
        case .unknown(let msg):
            return msg
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your Wi-Fi or cellular connection and try again."
        case .rateLimited:
            return "Wait a few seconds and try again."
        default:
            return "Pull to refresh or try again."
        }
    }
}