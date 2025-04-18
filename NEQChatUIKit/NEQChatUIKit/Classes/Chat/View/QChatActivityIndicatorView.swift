
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

enum QChatSendMessageStatus {
  case successed
  case sending
  case failed
}

class QChatActivityIndicatorView: UIButton {
  public var messageStatus: QChatSendMessageStatus? {
    didSet {
      failBtn.isHidden = true
      activity.isHidden = true
      activity.stopAnimating()

      switch messageStatus {
      case .sending:
        isHidden = false
        activity.isHidden = false
        activity.startAnimating()
      case .failed:
        isHidden = false
        failBtn.isHidden = false
      case .successed:
        isHidden = true
      default:
        print("")
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    addSubview(failBtn)
    addSubview(activity)
    NSLayoutConstraint.activate([
      failBtn.topAnchor.constraint(equalTo: topAnchor),
      failBtn.leftAnchor.constraint(equalTo: leftAnchor),
      failBtn.bottomAnchor.constraint(equalTo: bottomAnchor),
      failBtn.rightAnchor.constraint(equalTo: rightAnchor),
    ])

    NSLayoutConstraint.activate([
      activity.topAnchor.constraint(equalTo: topAnchor),
      activity.leftAnchor.constraint(equalTo: leftAnchor),
      activity.bottomAnchor.constraint(equalTo: bottomAnchor),
      activity.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }

  // MARK: lazy Method

  private lazy var failBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isUserInteractionEnabled = false
    button.setBackgroundImage(UIImage.ne_imageNamed(name: "sendMessage_failed"), for: .normal)
    return button
  }()

  private lazy var activity: UIActivityIndicatorView = {
    let activity = UIActivityIndicatorView()
    activity.translatesAutoresizingMaskIntoConstraints = false
    activity.color = .gray
    return activity
  }()
}
