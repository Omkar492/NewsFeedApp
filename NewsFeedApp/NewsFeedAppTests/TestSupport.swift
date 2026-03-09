//
//  TestSupport.swift
//  NewsFeedAppTests
//
//  Created by Omkar Chougule on 09/03/26.
//

import XCTest
import Combine
@testable import NewsFeedApp

@MainActor
extension XCTestCase {
    func awaitPublisher<T>(_ publisher: AnyPublisher<T, AppError>,
                           timeout: TimeInterval = 2,
                           file: StaticString = #filePath,
                           line: UInt = #line) throws -> T {
        let expectation = expectation(description: "Awaiting publisher")
        var output: T?
        var completionError: AppError?
        var cancellables = Set<AnyCancellable>()

        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        completionError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { value in
                    output = value
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: timeout)

        if let completionError {
            throw completionError
        }

        return try XCTUnwrap(output, file: file, line: line)
    }

    func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
