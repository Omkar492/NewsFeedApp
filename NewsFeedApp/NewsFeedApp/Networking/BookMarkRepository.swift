//
//  CoreDataStack.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import Foundation
import CoreData
import Combine

// MARK: - CoreData Stack
final class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NewsApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private init() {}
}

// MARK: - Bookmark Repository Implementation
final class BookmarkRepository: BookmarkRepositoryProtocol {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    func fetchBookmarks() -> AnyPublisher<[Article], AppError> {
        Future { [weak self] promise in
            guard let self else { return }
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BookmarkedArticleMO> = BookmarkedArticleMO.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
            do {
                let results = try context.fetch(request)
                let articles = results.compactMap { $0.toArticle() }
                promise(.success(articles))
            } catch {
                promise(.failure(.unknown(error.localizedDescription)))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func saveBookmark(_ article: Article) -> AnyPublisher<Void, AppError> {
        Future { [weak self] promise in
            guard let self else { return }
            let context = self.coreDataStack.newBackgroundContext()
            context.perform {
                let mo = BookmarkedArticleMO(context: context)
                mo.populate(from: article)
                self.coreDataStack.save(context: context)
                promise(.success(()))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func removeBookmark(id: String) -> AnyPublisher<Void, AppError> {
        Future { [weak self] promise in
            guard let self else { return }
            let context = self.coreDataStack.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<BookmarkedArticleMO> = BookmarkedArticleMO.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                if let object = try? context.fetch(request).first {
                    context.delete(object)
                    self.coreDataStack.save(context: context)
                }
                promise(.success(()))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func isBookmarked(id: String) -> AnyPublisher<Bool, AppError> {
        Just(isBookmarkedSync(id: id))
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }

    func isBookmarkedSync(id: String) -> Bool {
        let request: NSFetchRequest<BookmarkedArticleMO> = BookmarkedArticleMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        let count = (try? coreDataStack.viewContext.count(for: request)) ?? 0
        return count > 0
    }
}

// MARK: - NSManagedObject Extension
extension BookmarkedArticleMO {
    func populate(from article: Article) {
        self.id = article.id
        self.title = article.title
        self.articleDescription = article.description
        self.content = article.content
        self.author = article.author
        self.sourceName = article.sourceName
        self.imageURL = article.imageURL?.absoluteString
        self.articleURL = article.url?.absoluteString
        self.publishedAt = article.publishedAt
        self.savedAt = Date()
        self.category = article.category?.rawValue
    }

    func toArticle() -> Article? {
        guard let id = id, let title = title else { return nil }
        return Article(
            id: id,
            title: title,
            description: articleDescription,
            content: content,
            author: author,
            sourceName: sourceName ?? "Unknown",
            sourceURL: articleURL.flatMap { URL(string: $0) },
            imageURL: imageURL.flatMap { URL(string: $0) },
            publishedAt: publishedAt ?? Date(),
            url: articleURL.flatMap { URL(string: $0) },
            category: category.flatMap { NewsCategory(rawValue: $0) },
            isBookmarked: true
        )
    }
}