
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class QChatEmojiCommentCell: QChatEmojiCell {
  public lazy var countLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()

  public var imageViewLeftConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    layer.cornerRadius = 13
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func setupUI() {
    contentView.addSubview(imageView)
    contentView.addSubview(countLabel)

    imageViewLeftConstraint = imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 5)
    imageViewLeftConstraint?.isActive = true
    NSLayoutConstraint.activate([
      imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 20),
      imageView.heightAnchor.constraint(equalToConstant: 20),
    ])
  }

  public func addCountLabel(_ label: String, width: CGFloat) {
    imageViewLeftConstraint?.constant = 5
    countLabel.text = label
    countLabel.frame = CGRect(x: 29, y: 5, width: width, height: 16)
  }

  public func removeCountLabel() {
    imageViewLeftConstraint?.constant = 3
    countLabel.frame = .zero
  }

  public func setCountLabel(highlight: Bool) {
    if highlight {
      countLabel.textColor = .ne_blueText
      countLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    } else {
      countLabel.textColor = .ne_greyText
      countLabel.font = .systemFont(ofSize: 16, weight: .medium)
    }
  }
}
