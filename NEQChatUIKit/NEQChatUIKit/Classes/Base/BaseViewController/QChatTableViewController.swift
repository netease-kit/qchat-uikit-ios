
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import UIKit

public class QChatTableViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public var tableView: UITableView = .init(frame: .zero, style: .grouped)

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    tableView.sectionHeaderHeight = 38
    tableView.sectionFooterHeight = 0
    tableView.rowHeight = 62
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    0
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
