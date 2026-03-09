//
//  ImageLoader.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private let urlCache: URLCache

    private init() {
        self.urlCache = URLCache(memoryCapacity: AppConstants.Images.memoryCacheSize,
                                 diskCapacity: AppConstants.Images.diskCacheSize,
                                 diskPath: AppConstants.Images.cacheDirectoryName)
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = urlCache
        self.session = URLSession(configuration: configuration)
    }

    @discardableResult
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        let nsURL = url as NSURL
        if let image = memoryCache.object(forKey: nsURL) {
            completion(image)
            return nil
        }

        let request = URLRequest(url: url,
                                 cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: AppConstants.Network.requestTimeout)

        if let cachedResponse = urlCache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            memoryCache.setObject(image, forKey: nsURL)
            completion(image)
            return nil
        }

        let task = session.dataTask(with: request) { [weak self] data, response, _ in
            guard let self, let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self.memoryCache.setObject(image, forKey: nsURL)

            if let response {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                self.urlCache.storeCachedResponse(cachedResponse, for: request)
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }

        task.resume()
        return task
    }
}
