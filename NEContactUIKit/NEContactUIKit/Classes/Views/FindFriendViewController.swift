
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreKit
import NECoreIMKit
@objcMembers
public class FindFriendViewController: ContactBaseViewController, UITextFieldDelegate {
  let viewModel = FindFriendViewModel()
  let noResultView = UIView()
  let hasRequest = false
  let searchInput = UITextField()

  override public func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("add_friend")
    emptyView.setttingContent(content: localizable("user_not_exist"))
    setupUI()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = false
  }

  func setupUI() {
    let searchBack = UIView()
    view.addSubview(searchBack)
    searchBack.backgroundColor = UIColor(hexString: "F2F4F5")
    searchBack.translatesAutoresizingMaskIntoConstraints = false
    searchBack.clipsToBounds = true
    searchBack.layer.cornerRadius = 4.0
    NSLayoutConstraint.activate([
      searchBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      searchBack.heightAnchor.constraint(equalToConstant: 32),
    ])

    let searchImage = UIImageView()
    searchBack.addSubview(searchImage)
    searchImage.image = UIImage.ne_imageNamed(name: "search")
    searchImage.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchImage.centerYAnchor.constraint(equalTo: searchBack.centerYAnchor),
      searchImage.leftAnchor.constraint(equalTo: searchBack.leftAnchor, constant: 18),
      searchImage.widthAnchor.constraint(equalToConstant: 13),
      searchImage.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBack.addSubview(searchInput)
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImage.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBack.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBack.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBack.bottomAnchor),
    ])
    searchInput.textColor = UIColor(hexString: "333333")
    searchInput.placeholder = localizable("input_userId")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.delegate = self
    searchInput.clearButtonMode = .always

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textFieldChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.topAnchor.constraint(equalTo: searchInput.bottomAnchor, constant: 74),
      // emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text else {
      return false
    }
    if text.count <= 0 {
      return false
    }
    if hasRequest == false {
      startSearch(text)
    }
    return true
  }

  func textFieldChange() {
    if let text = searchInput.text, text.count <= 0 {
      emptyView.isHidden = true
    }
  }

  func startSearch(_ text: String) {
    weak var weakSelf = self
    viewModel.searchFriend(text) { users, error in
      NELog.infoLog(
        "FindFriendViewController",
        desc: "CALLBACK searchFriend " + (error?.localizedDescription ?? "no error")
      )
      if error == nil {
        if let user = users?.first {
          // go to detail
          let userController = ContactUserViewController(user: user)
          self.navigationController?.pushViewController(userController, animated: true)
          weakSelf?.emptyView.isHidden = true
        } else {
          weakSelf?.emptyView.isHidden = false
        }
      } else {
        self.showToast(error?.localizedDescription ?? "")
      }
    }
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
