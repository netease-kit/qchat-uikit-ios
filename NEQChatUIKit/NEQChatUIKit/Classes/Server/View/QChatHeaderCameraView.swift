
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class QChatHeaderCameraView: QChatHeaderView {
  public lazy var cameraBtn: ExpandButton = {
    let cameraBtn = ExpandButton()
    cameraBtn.layer.cornerRadius = 12
    cameraBtn.clipsToBounds = true
    cameraBtn.layer.borderColor = UIColor.white.cgColor
    cameraBtn.layer.borderWidth = 2
    cameraBtn.backgroundColor = .ne_backcolor
    return cameraBtn
  }()

  override public func setupUI() {
    super.setupUI()
    addSubview(cameraBtn)
    cameraBtn.translatesAutoresizingMaskIntoConstraints = false
    cameraBtn.backgroundColor = .ne_backcolor
    NSLayoutConstraint.activate([
      cameraBtn.centerXAnchor.constraint(equalTo: headerView.rightAnchor, constant: -6),
      cameraBtn.centerYAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -6),
      cameraBtn.widthAnchor.constraint(equalToConstant: 26),
      cameraBtn.heightAnchor.constraint(equalToConstant: 26),
    ])
    cameraBtn.layer.cornerRadius = 12
    cameraBtn.clipsToBounds = true
    cameraBtn.layer.borderColor = UIColor.white.cgColor
    cameraBtn.layer.borderWidth = 2
  }
}
