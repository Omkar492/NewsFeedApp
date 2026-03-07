//
//  SupportingViews.swift
//  NewsFeedApp
//
//  Created by Omkar Chougule on 07/03/26.
//

import Foundation
import UIKit

// MARK: - Empty State View
final class EmptyStateView: UIView {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .tertiaryLabel
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .title2)
        l.fontDescrip(weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .capsule
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    var onActionTapped: (() -> Void)?

    init(systemImage: String, title: String, subtitle: String, actionTitle: String? = nil) {
        super.init(frame: .zero)
        imageView.image = UIImage(systemName: systemImage)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 60, weight: .light))
        titleLabel.text = title
        subtitleLabel.text = subtitle
        if let actionTitle = actionTitle {
            actionButton.configuration?.title = actionTitle
            actionButton.isHidden = false
        }
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        stackView.addArrangedSubview(imageView)
        stackView.setCustomSpacing(16, after: imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.setCustomSpacing(20, after: subtitleLabel)
        stackView.addArrangedSubview(actionButton)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    @objc private func actionTapped() { onActionTapped?() }
}

// MARK: - UILabel font helper
extension UILabel {
    func fontDescrip(weight: UIFont.Weight) {
        let descriptor = font.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        font = UIFont(descriptor: descriptor, size: 0)
    }
}

// MARK: - Loading Footer View
final class LoadingFooterView: UICollectionReusableView {
    static let reuseIdentifier = "LoadingFooterView"
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        spinner.startAnimating()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(isLoading: Bool) {
        isHidden = !isLoading
        if isLoading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
}

// MARK: - Category Filter Cell
final class CategoryFilterCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryFilterCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.fontDescrip(weight: .medium)
        l.textAlignment = .center
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with category: NewsCategory) {
        titleLabel.text = category.displayName
    }

    private func updateAppearance() {
        if isSelected {
            contentView.backgroundColor = .systemBlue
            titleLabel.textColor = .white
        } else {
            contentView.backgroundColor = .secondarySystemBackground
            titleLabel.textColor = .label
        }
    }
}
