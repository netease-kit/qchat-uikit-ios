
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit

class NEHomeChannelCell: UITableViewCell {
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  public var channelModel: ChatChannel? {
    didSet {
      guard var name = channelModel?.name else { return }
      name = "# \(name)"
      let attrStr = NSMutableAttributedString(string: name)
      attrStr.addAttribute(
        NSAttributedString.Key.foregroundColor,
        value: PlaceholderTextColor,
        range: NSRange(location: 0, length: 1)
      )
      attrStr.addAttribute(
        NSAttributedString.Key.foregroundColor,
        value: TextNormalColor,
        range: NSRange(location: 1, length: name.count - 1)
      )
      channelNameLabel.attributedText = attrStr
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    contentView.addSubview(channelNameLabel)
    contentView.addSubview(redAngleView)

    NSLayoutConstraint.activate([
      channelNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 18),
      channelNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      channelNameLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -50
      ),

    ])

    NSLayoutConstraint.activate([
      redAngleView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -18),
      redAngleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  private lazy var channelNameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(16)
    label.textColor = TextNormalColor
    return label
  }()

  lazy var redAngleView: RedAngleLabel = {
    let label = RedAngleLabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(12)
    label.textColor = .white
    label.text = "99+"
    label.backgroundColor = HexRGB(0xF24957)
    label.textInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
    label.layer.cornerRadius = 9
    label.clipsToBounds = true
    label.isHidden = true
    return label
  }()
}
