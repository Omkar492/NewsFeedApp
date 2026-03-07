//
//  MainTabBarController.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//

import UIKit

// MARK: - Main Tab Bar Controller
final class MainTabBarController: UITabBarController {
    private let container = AppDependencyContainer.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let feedVC = makeFeedTab()
        let searchVC = makeSearchTab()
        let bookmarksVC = makeBookmarksTab()
        viewControllers = [feedVC, searchVC, bookmarksVC]
    }

    private func makeFeedTab() -> UINavigationController {
        let vm = container.makeFeedViewModel()
        let vc = FeedViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: "News", image: UIImage(systemName: "newspaper"), tag: 0)
        return UINavigationController(rootViewController: vc)
    }

    private func makeSearchTab() -> UINavigationController {
        let vm = container.makeSearchViewModel()
        let vc = SearchViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        return UINavigationController(rootViewController: vc)
    }

    private func makeBookmarksTab() -> UINavigationController {
        let vm = container.makeBookmarksViewModel()
        let vc = BookmarksViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(systemName: "bookmark"), tag: 2)
        return UINavigationController(rootViewController: vc)
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemBlue
    }
}
