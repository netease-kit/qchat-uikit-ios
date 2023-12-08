
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatHeaderCell: QChatCornerCell {
  var user: QChatUserInfo? {
    didSet {
      if let name = user?.nickName {
        headerView.configHeadData(headUrl: user?.avatar, name: name, uid: user?.accid ?? "")
        nameLabel.text = name
      } else if let aid = user?.accid {
        headerView.configHeadData(headUrl: user?.avatar, name: aid, uid: user?.accid ?? "")
        nameLabel.text = aid
      }
      headerView.backgroundColor = user?.color
    }
  }

  let headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = DefaultTextFont(20)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 30
    header.translatesAutoresizingMaskIntoConstraints = false
//        header.backgroundColor = UIColor.randomColor()

    return header
  }()

  let nameLabel: UILabel = {
    let label = UILabel()
    label.textColor = .ne_darkText
    label.font = DefaultTextFont(16)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
    setupUI()
  }

  func setupUI() {
    contentView.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 60),
      headerView.heightAnchor.constraint(equalToConstant: 60),
    ])
    headerView.addCorner(conrners: .allCorners, radius: 30)

    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 16),
      nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }
}
