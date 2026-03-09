//
//  ArticleCell.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//

import Foundation
import UIKit

// MARK: - Article Cell
final class ArticleCell: UICollectionViewCell {
    static let reuseIdentifier = "ArticleCell"

    // MARK: - UI
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tertiarySystemBackground
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.textColor = .systemBlue
        l.numberOfLines = 1
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.numberOfLines = 3
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sourceLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.textColor = .secondaryLabel
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.textColor = .tertiaryLabel
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bookmarkButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: AppConstants.Symbols.bookmark)
        config.baseForegroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        config.baseBackgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.8)
            : UIColor.black.withAlphaComponent(0.8)
        }
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: AppConstants.Layout.bookmarkButtonContentInset,
                                                       leading: AppConstants.Layout.bookmarkButtonContentInset,
                                                       bottom: AppConstants.Layout.bookmarkButtonContentInset,
                                                       trailing: AppConstants.Layout.bookmarkButtonContentInset)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let sourceDateStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var imageTask: URLSessionDataTask?
    private var currentImageURL: URL?
    var onBookmarkTapped: (() -> Void)?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        currentImageURL = nil
        thumbnailImageView.image = nil
        thumbnailImageView.tintColor = nil
        categoryLabel.text = nil
        onBookmarkTapped = nil
    }

    // MARK: - Configure
    func configure(with article: Article) {
        titleLabel.text = article.title
        sourceLabel.text = article.sourceName
        dateLabel.text = article.publishedAt.relativeFormatted
        categoryLabel.text = article.category?.displayName.uppercased()
        updateBookmarkIcon(isBookmarked: article.isBookmarked)

        if let imageURL = article.imageURL {
            loadImage(from: imageURL)
        } else {
            thumbnailImageView.image = UIImage(systemName: AppConstants.Symbols.newspaperFill)
            thumbnailImageView.tintColor = .tertiaryLabel
        }
    }

    func updateBookmarkIcon(isBookmarked: Bool) {
        let imageName = isBookmarked ? AppConstants.Symbols.bookmarkFill : AppConstants.Symbols.bookmark
        bookmarkButton.configuration?.image = UIImage(systemName: imageName)
    }

    // MARK: - Private
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        thumbnailImageView.addSubview(bookmarkButton)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(titleLabel)
        sourceDateStack.addArrangedSubview(sourceLabel)
        sourceDateStack.addArrangedSubview(UIView()) // spacer
        sourceDateStack.addArrangedSubview(dateLabel)
        containerView.addSubview(sourceDateStack)
        bookmarkButton.setContentHuggingPriority(.required, for: .horizontal)
        bookmarkButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppConstants.Layout.articleCardVerticalInset),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppConstants.Layout.articleCardHorizontalInset),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppConstants.Layout.articleCardHorizontalInset),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppConstants.Layout.articleCardVerticalInset),

            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: AppConstants.Layout.articleImageHeight),

            bookmarkButton.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: AppConstants.Layout.bookmarkOverlayInset),
            bookmarkButton.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -AppConstants.Layout.bookmarkOverlayInset),

            categoryLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: AppConstants.Layout.articleContentInset),
            categoryLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppConstants.Layout.articleContentInset),
            categoryLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppConstants.Layout.articleContentInset),

            titleLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppConstants.Layout.articleContentInset),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppConstants.Layout.articleContentInset),

            sourceDateStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            sourceDateStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppConstants.Layout.articleContentInset),
            sourceDateStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppConstants.Layout.articleContentInset),
            sourceDateStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppConstants.Layout.articleContentInset),

            bookmarkButton.widthAnchor.constraint(equalToConstant: AppConstants.Layout.bookmarkButtonSize),
            bookmarkButton.heightAnchor.constraint(equalToConstant: AppConstants.Layout.bookmarkButtonSize)
        ])

        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false
    }

    private func loadImage(from url: URL) {
        currentImageURL = url
        thumbnailImageView.image = UIImage(systemName: AppConstants.Symbols.photo)
        thumbnailImageView.tintColor = .tertiaryLabel

        imageTask = ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self, self.currentImageURL == url else { return }
            guard let image else { return }

            UIView.transition(with: self.thumbnailImageView,
                              duration: 0.2,
                              options: .transitionCrossDissolve) {
                self.thumbnailImageView.image = image
                self.thumbnailImageView.tintColor = nil
            }
        }
    }

    @objc private func bookmarkTapped() {
        onBookmarkTapped?()
    }
}

// MARK: - Date Extension
extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
