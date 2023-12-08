
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NECoreQChatKit
import UIKit

class QChatHomeServerCell: UITableViewCell {
  lazy var redDot: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .ne_redColor
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.layer.borderColor = UIColor.white.cgColor
    view.layer.borderWidth = 1
    view.isHidden = true
    return view
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  public var serverModel: QChatServer? {
    didSet {
      if let imageUrl = serverModel?.icon {
        headView.sd_setImage(with: URL(string: imageUrl), completed: nil)
        headView.setTitle("")
      } else {
        if let name = serverModel?.name {
          headView.setTitle(name)
        }
        headView.sd_setImage(with: URL(string: ""), completed: nil)
        headView.backgroundColor = .colorWithNumber(number: serverModel?.serverId)
      }

//      if let hasUnread = serverModel?.hasUnread {
//        redDot.isHidden = !hasUnread
//      }
      if let unreadCount = serverModel?.unreadCount, unreadCount > 0 {
        redAngleView.isHidden = false
        if unreadCount <= 99 {
          redAngleView.text = "\(unreadCount)"
        } else {
          redAngleView.text = "99+"
        }
      } else {
        redAngleView.isHidden = true
      }

      if serverModel?.announce == nil {
        noticeTag.isHidden = true
      } else {
        noticeTag.isHidden = false
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    clipsToBounds = false
    contentView.clipsToBounds = false
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    contentView.addSubview(leftSelectView)
    contentView.addSubview(headView)

    NSLayoutConstraint.activate([
      headView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      headView.topAnchor.constraint(equalTo: contentView.topAnchor),
      headView.widthAnchor.constraint(equalToConstant: 42),
      headView.heightAnchor.constraint(equalToConstant: 42),
    ])

    NSLayoutConstraint.activate([
      leftSelectView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: -4),
      leftSelectView.topAnchor.constraint(equalTo: contentView.topAnchor),
      leftSelectView.widthAnchor.constraint(equalToConstant: 8),
      leftSelectView.heightAnchor.constraint(equalToConstant: 36),
    ])

    let factor = cos(45 * Double.pi / 180)
    contentView.addSubview(redAngleView)
    NSLayoutConstraint.activate([
      redAngleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 21 * factor),
      redAngleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -21 * factor),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])

    contentView.addSubview(noticeTag)
    NSLayoutConstraint.activate([
      noticeTag.rightAnchor.constraint(equalTo: headView.rightAnchor, constant: 0),
      noticeTag.bottomAnchor.constraint(equalTo: headView.bottomAnchor, constant: 0),
      noticeTag.widthAnchor.constraint(equalToConstant: 14),
      noticeTag.heightAnchor.constraint(equalToConstant: 14),
    ])

    noticeTag.addSubview(noticeTagImageView)
    NSLayoutConstraint.activate([
      noticeTagImageView.centerYAnchor.constraint(equalTo: noticeTag.centerYAnchor),
      noticeTagImageView.centerXAnchor.constraint(equalTo: noticeTag.centerXAnchor),
    ])
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    headView.addCorner(conrners: .allCorners, radius: 21)
  }

  // MARK: lazy method

  private lazy var leftSelectView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = HexRGB(0x337EFF)
    view.layer.cornerRadius = 4
    view.isHidden = true
    return view
  }()

  lazy var headView: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.textColor = .white
    view.titleLabel.font = DefaultTextFont(14)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
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

  lazy var noticeTag: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 7.0
    view.clipsToBounds = true
    view.layer.borderWidth = 2.0
    view.layer.borderColor = UIColor.ne_lightBackgroundColor.cgColor
    view.backgroundColor = UIColor.ne_noticeTagBackgroundColor
    return view
  }()

  lazy var noticeTagImageView: UIImageView = {
    let tagImageView = UIImageView()
    tagImageView.translatesAutoresizingMaskIntoConstraints = false
    tagImageView.image = UIImage.ne_imageNamed(name: "notice_tag")
    return tagImageView
  }()

  public func showSelectState(isShow: Bool) {
    leftSelectView.isHidden = isShow ? false : true
  }
}
