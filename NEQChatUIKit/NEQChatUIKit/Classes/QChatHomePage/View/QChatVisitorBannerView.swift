//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class QChatVisitorBannerView: UIView {
  /*
   // Only override draw() if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   override func draw(_ rect: CGRect) {
       // Drawing code
   }
   */

  public var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage.ne_imageNamed(name: "horn_icon")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  public var titleLabel: UILabel = {
    let label = UILabel()
    label.text = localizable("visitor_banner_text")
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = UIColor(hexString: "#333333")
    label.translatesAutoresizingMaskIntoConstraints = false
    // 根据文本自动适应字体
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  // 加入按钮
  public var joinButton: ExpandButton = {
    let button = ExpandButton()
    button.setTitle(localizable("visitor_banner_join"), for: .normal)
    button.setTitleColor(UIColor(hexString: "#FFFFFF"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
    button.backgroundColor = UIColor(hexString: "#337EFF")
    button.layer.cornerRadius = 2.0
    button.clipsToBounds = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  // 背景图片 ImageView
  public var backgroundImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage.ne_imageNamed(name: "visitor_banner_bg")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    addSubview(backgroundImageView)
    addSubview(imageView)
    addSubview(titleLabel)
    addSubview(joinButton)

    let offset: CGFloat = 8.0
    NSLayoutConstraint.activate([
      backgroundImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: -offset),
      backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: -offset),
      backgroundImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: offset),
      backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset),
    ])

    NSLayoutConstraint.activate([
      imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 18),
      imageView.centerYAnchor.constraint(equalTo: centerYAnchor),

    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 42),
      titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -77),
    ])

    NSLayoutConstraint.activate([
      joinButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
      joinButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      joinButton.widthAnchor.constraint(equalToConstant: 57),
      joinButton.heightAnchor.constraint(equalToConstant: 26),
    ])
  }
}
