
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NIMSDK
import UIKit

@objc
@objcMembers
open class QChatHomeChannelCell: UITableViewCell {
  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    redAngleView.backgroundColor = HexRGB(0xF24957)
  }

  public var channelModel: ChatChannel? {
    didSet {
      guard let name = channelModel?.name else { return }
      channelNameLabel.text = name
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    let selectView = UIView()
    selectView.layer.cornerRadius = 2.0
    selectView.clipsToBounds = true
    selectView.backgroundColor = UIColor(hexString: "#F3F5F7")
    selectedBackgroundView = selectView
    selectionStyle = .default
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    contentView.addSubview(backView)
    backView.addSubview(channelNameLabel)
    backView.addSubview(redAngleView)
    backView.addSubview(lastMsgLabel)
    backView.addSubview(placeholderLabel)

    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      backView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
    ])

    NSLayoutConstraint.activate([
      channelNameLabel.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 30),
      channelNameLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 8),
      channelNameLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -50
      ),

    ])

    NSLayoutConstraint.activate([
      redAngleView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -18),
      redAngleView.centerYAnchor.constraint(equalTo: channelNameLabel.centerYAnchor),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      lastMsgLabel.leftAnchor.constraint(equalTo: channelNameLabel.leftAnchor),
      lastMsgLabel.topAnchor.constraint(equalTo: channelNameLabel.bottomAnchor, constant: 0),
      lastMsgLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -18),
    ])

    NSLayoutConstraint.activate([
      placeholderLabel.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 18),
      placeholderLabel.centerYAnchor.constraint(equalTo: channelNameLabel.centerYAnchor),
    ])
  }

  public func setLastMessage(_ text: String?) {
    lastMsgLabel.text = text
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

  lazy var lastMsgLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(12)
    label.textColor = HexRGB(0x999999)
    return label
  }()

  // 占位label
  lazy var placeholderLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(16)
    label.textColor = PlaceholderTextColor
    label.text = "#"
    return label
  }()

  // 背景视图
  lazy var backView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear
    return view
  }()
}
