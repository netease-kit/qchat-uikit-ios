
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class QChatHeaderView: UIView {
  let headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = DefaultTextFont(20)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 30
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  let nameLabel: UILabel = {
    let label = UILabel()
    label.textColor = .ne_darkText
    label.font = DefaultTextFont(16)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func setupUI() {
    clipsToBounds = true
    layer.cornerRadius = 8
    backgroundColor = .white
    addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
      headerView.centerYAnchor.constraint(equalTo: centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 60),
      headerView.heightAnchor.constraint(equalToConstant: 60),
    ])

    addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 8),
      nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
      nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  open func configure(iconUrl: String?, name: String?, uid: UInt64) {
    headerView.configHeadData(headUrl: iconUrl, name: name ?? "", uid: "\(uid)")
    headerView.backgroundColor = .colorWithNumber(number: uid)
    nameLabel.text = (name?.count ?? 0) > 0 ? name : "\(uid)"
  }
}
