
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import UIKit
class QChatImageTableViewCell: QChatBaseTableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var contentImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    self.contentBtn.addSubview(imageView)
    imageView.clipsToBounds = true
    return imageView
  }()

  override public var messageFrame: QChatMessageFrame? {
    didSet {
      let imageObject = messageFrame?.message?.messageObject as! NIMImageObject
      contentImageView.frame = CGRect(
        x: messageFrame?.startX ?? 0,
        y: qChat_margin,
        width: messageFrame?.contentSize.width ?? 0,
        height: messageFrame?.contentSize.height ?? 0
      )
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
        contentImageView.sd_setImage(
          with: URL(fileURLWithPath: path),
          placeholderImage: nil,
          options: .retryFailed,
          progress: nil,
          completed: nil
        )
      } else if let imageUrl = imageObject.url {
        contentImageView.sd_setImage(
          with: URL(string: imageUrl),
          placeholderImage: nil,
          options: .retryFailed,
          progress: nil,
          completed: nil
        )
      } else {
        contentImageView.image = UIImage()
      }
    }
  }
}
