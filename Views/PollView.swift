// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class PollView: UIView {
    private let stackView = UIStackView()
    private let voteButtonStackView = UIStackView()
    private let bottomStackView = UIStackView()
    private let voteButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)
    private let refreshDividerLabel = UILabel()
    private let votesCountLabel = UILabel()
    private let votesCountDividerLabel = UILabel()
    private let expiryLabel = UILabel()
    private var selectionCancellable: AnyCancellable?

    var viewModel: StatusViewModel? {
        didSet {
            for view in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            guard let viewModel = viewModel else {
                selectionCancellable = nil

                return
            }

            if !viewModel.isPollExpired, !viewModel.hasVotedInPoll {
                for (index, option) in viewModel.pollOptions.enumerated() {
                    let button = PollOptionButton(
                        title: option.title,
                        emoji: viewModel.pollEmoji,
                        multipleSelection: viewModel.isPollMultipleSelection)

                    button.addAction(
                        UIAction { _ in
                            if viewModel.pollOptionSelections.contains(index) {
                                viewModel.pollOptionSelections.remove(index)
                            } else if viewModel.isPollMultipleSelection {
                                viewModel.pollOptionSelections.insert(index)
                            } else {
                                viewModel.pollOptionSelections = [index]
                            }
                        },
                        for: .touchUpInside)

                    stackView.addArrangedSubview(button)
                }
            } else {
                for (index, option) in viewModel.pollOptions.enumerated() {
                    let resultView = PollResultView(
                        option: option,
                        emoji: viewModel.pollEmoji,
                        selected: viewModel.pollOwnVotes.contains(index),
                        multipleSelection: viewModel.isPollMultipleSelection,
                        votersCount: viewModel.pollVotersCount)

                    stackView.addArrangedSubview(resultView)
                }
            }

            if !viewModel.isPollExpired, !viewModel.hasVotedInPoll {
                stackView.addArrangedSubview(voteButtonStackView)

                selectionCancellable = viewModel.$pollOptionSelections.sink { [weak self] in
                    guard let self = self else { return }

                    for (index, view) in self.stackView.arrangedSubviews.enumerated() {
                        (view as? UIButton)?.isSelected = $0.contains(index)
                    }

                    self.voteButton.isEnabled = !$0.isEmpty
                }
            } else {
                selectionCancellable = nil
            }

            stackView.addArrangedSubview(bottomStackView)

            votesCountLabel.text = String.localizedStringWithFormat(
                NSLocalizedString("status.poll.participation-count", comment: ""),
                viewModel.pollVotersCount)

            if !viewModel.isPollExpired, let pollTimeLeft = viewModel.pollTimeLeft {
                expiryLabel.text = String.localizedStringWithFormat(
                    NSLocalizedString("status.poll.time-left", comment: ""),
                    pollTimeLeft)
                refreshButton.isHidden = false
            } else {
                expiryLabel.text = NSLocalizedString("status.poll.closed", comment: "")
                refreshButton.isHidden = true
            }

            refreshDividerLabel.isHidden = refreshButton.isHidden
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PollView {
    func initialSetup() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        voteButtonStackView.addArrangedSubview(voteButton)
        voteButtonStackView.addArrangedSubview(UIView())

        voteButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        voteButton.titleLabel?.adjustsFontForContentSizeCategory = true
        voteButton.setTitle(NSLocalizedString("status.poll.vote", comment: ""), for: .normal)
        voteButton.addAction(UIAction { [weak self] _ in self?.viewModel?.vote() }, for: .touchUpInside)

        bottomStackView.spacing = .compactSpacing

        bottomStackView.addArrangedSubview(refreshButton)
        refreshButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        refreshButton.titleLabel?.adjustsFontForContentSizeCategory = true
        refreshButton.setTitle(NSLocalizedString("status.poll.refresh", comment: ""), for: .normal)
        refreshButton.addAction(UIAction { [weak self] _ in self?.viewModel?.refreshPoll() }, for: .touchUpInside)

        for label in [refreshDividerLabel, votesCountLabel, votesCountDividerLabel, expiryLabel] {
            bottomStackView.addArrangedSubview(label)
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            label.adjustsFontForContentSizeCategory = true
        }

        refreshDividerLabel.text = "•"
        votesCountDividerLabel.text = "•"

        bottomStackView.addArrangedSubview(UIView())

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}