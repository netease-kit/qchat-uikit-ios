//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
@objcMembers
open class QChatSquareCollectionViewCell: UICollectionViewCell {
  public var squareImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()

  public var iconImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.layer.borderWidth = 2.0
    imageView.layer.borderColor = UIColor(hexString: "#E8E9EE").cgColor
    imageView.layer.cornerRadius = 6.0
    imageView.layer.masksToBounds = true
    return imageView
  }()

  public var squareTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = UIColor(hexString: "#333333")
    label.numberOfLines = 1
    return label
  }()

  public var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = UIColor(hexString: "#6E6F74")
    label.numberOfLines = 3
    return label
  }()

  public var hasJoinTagView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true
    view.layer.cornerRadius = 3.0
    view.backgroundColor = UIColor(hexString: "#4CAD5D")
    return view
  }()

  public var hasJoinLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 10.0)
    label.textColor = UIColor(hexString: "#6E6F74")
    label.numberOfLines = 1
    label.text = "已加入"
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.clipsToBounds = true
    contentView.layer.cornerRadius = 6.0
    contentView.backgroundColor = .white
    contentView.addSubview(squareImageView)
    NSLayoutConstraint.activate([
      squareImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      squareImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      squareImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      squareImageView.heightAnchor.constraint(equalToConstant: 82.0),
    ])

    contentView.addSubview(iconImageView)
    NSLayoutConstraint.activate([
      iconImageView.centerYAnchor.constraint(equalTo: squareImageView.bottomAnchor),
      iconImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12.0),
      iconImageView.widthAnchor.constraint(equalToConstant: 30.0),
      iconImageView.heightAnchor.constraint(equalToConstant: 30.0),
    ])

    contentView.addSubview(squareTitleLabel)
    NSLayoutConstraint.activate([
      squareTitleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10.0),
      squareTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12.0),
      squareTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12.0),
    ])

    contentView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.topAnchor.constraint(equalTo: squareTitleLabel.bottomAnchor, constant: 8.0),
      contentLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12.0),
      contentLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12.0),
    ])

    contentView.addSubview(hasJoinTagView)
    NSLayoutConstraint.activate([
      hasJoinTagView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16.0),
      hasJoinTagView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12.0),
      hasJoinTagView.widthAnchor.constraint(equalToConstant: 6.0),
      hasJoinTagView.heightAnchor.constraint(equalToConstant: 6.0),
    ])

    contentView.addSubview(hasJoinLabel)
    NSLayoutConstraint.activate([
      hasJoinLabel.centerYAnchor.constraint(equalTo: hasJoinTagView.centerYAnchor),
      hasJoinLabel.leftAnchor.constraint(equalTo: hasJoinTagView.rightAnchor, constant: 4.0),
    ])
  }

  public func configureData(server: QChatSquareServer) {
    squareTitleLabel.text = server.server?.name
    if let url = server.server?.icon {
      squareImageView.sd_setImage(with: URL(string: url))
      iconImageView.sd_setImage(with: URL(string: url))
    }
    if let custom = server.server?.custom, let dic = getDictionaryFromJSONString(custom) as? [String: String] {
      contentLabel.text = dic["topic"]
    }

    hasJoinLabel.isHidden = !server.isJoinedServer
    hasJoinTagView.isHidden = !server.isJoinedServer

//    contentLabel.text = "dsfafsadfasdfasdfsadfasdfsdfsadfsdfasdfasdf"
  }
}
