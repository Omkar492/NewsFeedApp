//
//  AppConstants.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 09/03/26.
//

import Foundation
import UIKit

enum AppConstants {
    enum Network {
        static let requestTimeout: TimeInterval = 30
        static let defaultPageSize = 20
        static let trendingPageSize = 5
        static let country = "us"
        static let language = "en"
        static let searchSortBy = "publishedAt"
    }

    enum Images {
        static let memoryCacheSize = 20 * 1024 * 1024
        static let diskCacheSize = 100 * 1024 * 1024
        static let cacheDirectoryName = "ImageLoaderCache"
    }

    enum Layout {
        static let articleCardHorizontalInset: CGFloat = 16
        static let articleCardVerticalInset: CGFloat = 4
        static let articleContentInset: CGFloat = 12
        static let bookmarkOverlayInset: CGFloat = 12
        static let bookmarkButtonSize: CGFloat = 44
        static let bookmarkButtonContentInset: CGFloat = 10
        static let articleImageHeight: CGFloat = 180
        static let estimatedArticleHeight: CGFloat = 300
        static let footerHeight: CGFloat = 50
        static let categoryChipHeight: CGFloat = 36
        static let categorySectionSpacing: CGFloat = 8
        static let categorySectionInset = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    enum Symbols {
        static let bookmark = "bookmark"
        static let bookmarkFill = "bookmark.fill"
        static let bookmarkSlash = "bookmark.slash"
        static let newspaper = "newspaper"
        static let newspaperFill = "newspaper.fill"
        static let magnifyingGlass = "magnifyingglass"
        static let searchEmpty = "doc.text.magnifyingglass"
        static let exclamation = "exclamationmark.circle"
        static let wifiExclamation = "wifi.exclamationmark"
        static let photo = "photo"
        static let share = "square.and.arrow.up"
        static let safari = "safari"
    }

    enum Titles {
        static let news = "News"
        static let search = "Search"
        static let bookmarks = "Bookmarks"
        static let error = "Error"
    }

    enum Messages {
        static let feedEmptyTitle = "No Articles"
        static let feedEmptySubtitle = "Pull to refresh to load the latest news."
        static let retry = "Retry"
        static let feedErrorTitle = "Couldn't Load News"
        static let feedErrorSubtitle = "Check your connection and try again."

        static let searchPlaceholder = "Search news, topics, sources..."
        static let searchIdleTitle = "Search for News"
        static let searchIdleSubtitle = "Type a keyword to find articles on any topic."
        static let searchEmptyTitle = "No Results"
        static let searchEmptySubtitle = "Try a different keyword or check your spelling."
        static let searchErrorTitle = "Search Failed"
        static let searchErrorSubtitle = "Please try again."

        static let bookmarksEmptyTitle = "No Bookmarks Yet"
        static let bookmarksEmptySubtitle = "Save articles while reading and they'll appear here."
        static let removeBookmark = "Remove Bookmark"
        static let ok = "OK"

        static let detailWebErrorTitle = "Couldn't Load Article"
        static let detailWebErrorMessage = "Would you like to open it in Safari instead?"
        static let openInSafari = "Open in Safari"
        static let cancel = "Cancel"
    }
}
