//
//  DetailViewController.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//


import UIKit
import WebKit
import Combine

// MARK: - Detail View Controller
final class DetailViewController: UIViewController {
    private let viewModel: DetailViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.tintColor = .systemBlue
        return pv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        return v
    }()

    private var bookmarkBarButton: UIBarButtonItem!
    private var progressObserver: NSKeyValueObservation?

    // MARK: - Init
    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        progressObserver?.invalidate()
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        bindViewModel()
        loadArticle()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(webView)
        view.addSubview(progressView)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        progressObserver = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, change in
            DispatchQueue.main.async {
                let progress = Float(change.newValue ?? 0)
                self?.progressView.setProgress(progress, animated: true)
                self?.progressView.isHidden = progress >= 1.0
            }
        }
    }

    private func setupNavigation() {
        title = viewModel.article.sourceName
        navigationItem.largeTitleDisplayMode = .never

        bookmarkBarButton = UIBarButtonItem(
            image: UIImage(systemName: viewModel.isBookmarked ? AppConstants.Symbols.bookmarkFill : AppConstants.Symbols.bookmark),
            style: .plain,
            target: self,
            action: #selector(toggleBookmark)
        )

        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: AppConstants.Symbols.share),
            style: .plain,
            target: self,
            action: #selector(shareArticle)
        )

        let safariButton = UIBarButtonItem(
            image: UIImage(systemName: AppConstants.Symbols.safari),
            style: .plain,
            target: self,
            action: #selector(openInSafari)
        )

        navigationItem.rightBarButtonItems = [shareButton, bookmarkBarButton, safariButton]
    }

    private func bindViewModel() {
        viewModel.$isBookmarked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBookmarked in
                let imageName = isBookmarked ? AppConstants.Symbols.bookmarkFill : AppConstants.Symbols.bookmark
                self?.bookmarkBarButton.image = UIImage(systemName: imageName)
                self?.animateBookmarkChange()
            }
            .store(in: &cancellables)
    }

    private func loadArticle() {
        if let url = viewModel.article.url {
            loadingIndicator.startAnimating()
            webView.load(URLRequest(url: url))
        }
    }

    private func animateBookmarkChange() {
        UIView.animate(withDuration: 0.15, animations: {
            self.bookmarkBarButton.customView?.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.bookmarkBarButton.customView?.transform = .identity
            }
        }
    }

    // MARK: - Actions
    @objc private func toggleBookmark() {
        viewModel.toggleBookmark()
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
    }

    @objc private func shareArticle() {
        let activityVC = UIActivityViewController(activityItems: viewModel.shareItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(activityVC, animated: true)
    }

    @objc private func openInSafari() {
        guard let url = viewModel.article.url else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - WKNavigationDelegate
extension DetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        showWebError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        showWebError()
    }

    private func showWebError() {
        let alert = UIAlertController(title: AppConstants.Messages.detailWebErrorTitle,
                                      message: AppConstants.Messages.detailWebErrorMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppConstants.Messages.openInSafari, style: .default) { [weak self] _ in
            self?.openInSafari()
        })
        alert.addAction(UIAlertAction(title: AppConstants.Messages.cancel, style: .cancel))
        present(alert, animated: true)
    }
}
