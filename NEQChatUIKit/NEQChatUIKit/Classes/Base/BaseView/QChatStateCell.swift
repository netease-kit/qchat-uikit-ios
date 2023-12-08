
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public enum RightStyle {
  case none
  case indicate
  case delete
}

open class QChatStateCell: QChatCornerCell {
  private var style: RightStyle = .none
  public var rightImage = UIImageView()
  var rightImageMargin: NSLayoutConstraint?
  var rightImageWidthAnchor: NSLayoutConstraint?
  public var rightStyle: RightStyle {
    get {
      style
    }
    set {
      style = newValue
      switch style {
      case .none:
        rightImage.image = nil
        rightImageWidthAnchor?.constant = 7
      case .indicate:
        rightImage.image = UIImage.ne_imageNamed(name: "arrowRight")
        rightImageWidthAnchor?.constant = 7
      case .delete:
        rightImage.image = UIImage.ne_imageNamed(name: "delete")
        rightImageWidthAnchor?.constant = 16
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    rightImage.contentMode = .center
    rightImage.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(rightImage)
    rightImageMargin = rightImage.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -36
    )
    rightImageMargin?.isActive = true
    rightImageWidthAnchor = rightImage.widthAnchor.constraint(equalToConstant: 0)
    rightImageWidthAnchor?.isActive = true
    NSLayoutConstraint.activate([
      rightImage.heightAnchor.constraint(equalToConstant: 20),
      rightImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }
}
