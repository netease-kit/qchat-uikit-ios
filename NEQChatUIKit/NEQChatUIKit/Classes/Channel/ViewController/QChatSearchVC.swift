
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class QChatSearchVC: NEBaseViewController, UITableViewDelegate, UITableViewDataSource {
  var textField = UITextField()
  var tableView = UITableView(frame: .zero, style: .plain)

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
  }

  func commonUI() {
//        textField.placeholder = "ddd";
//        textField.leftView = UIImageView(image: UIImage.ne_imageNamed(name: "search"))
//        textField.leftViewMode = .always
//        textField.layer.cornerRadius = 8;
//        textField.clipsToBounds = true
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        textField.backgroundColor = .ne_lightBackgroundColor
//        self.view.addSubview(textField)
//        if #available(iOS 11.0, *) {
//            NSLayoutConstraint.activate([
//                textField.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
//                textField.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20),
//                textField.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20),
//                textField.heightAnchor.constraint(equalToConstant: 32),
//            ])
//        } else {
//            NSLayoutConstraint.activate([
//                textField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),
//                textField.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20),
//                textField.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20),
//                textField.heightAnchor.constraint(equalToConstant: 32),
//            ])
//        }
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.rowHeight = 40
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(UITableViewCell.self)")

    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
    ])
  }

//    MARK: UITableViewDataSource

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(UITableViewCell.self)",
      for: indexPath
    )
    return cell
  }
}
