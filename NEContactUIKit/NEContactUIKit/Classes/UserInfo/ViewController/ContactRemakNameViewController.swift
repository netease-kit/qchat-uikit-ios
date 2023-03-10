
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NECoreKit

@objcMembers
public class ContactRemakNameViewController: ContactBaseViewController, UITextFieldDelegate {
  typealias ModifyBlock = (_ user: User) -> Void

  var completion: ModifyBlock?
  var user: User?
  let viewmodel = ContactUserViewModel()
  let textLimit = 15
  lazy var aliasInput: UITextField = {
    let textField = UITextField()
    textField.backgroundColor = .white
    textField.clipsToBounds = true
    textField.layer.cornerRadius = 8
    textField.font = UIFont.systemFont(ofSize: 16.0)
    textField.translatesAutoresizingMaskIntoConstraints = false
    let leftSpace = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
    textField.leftView = leftSpace
    textField.leftViewMode = .always
    textField.delegate = self
    textField.clearButtonMode = .whileEditing
    textField.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
    return textField
  }()

//    lazy var rightBtn: ExpandButton = {
//        let btn = ExpandButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
//        btn.setTitleColor(UIColor(hexString: "#337EFF"), for: .normal)
//        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
//        btn.addTarget(self, action: #selector(saveAlias), for: .touchUpInside)
//        return btn
//    }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    setupUI()
  }

  func setupUI() {
    view.backgroundColor = UIColor(hexString: "F2F4F5")
    let clearItem = UIBarButtonItem(
      title: localizable("save"),
      style: .done,
      target: self,
      action: #selector(saveAlias)
    )
    clearItem.tintColor = UIColor(hexString: "337EFF")
    navigationItem.rightBarButtonItem = clearItem
    title = localizable("noteName")
    view.addSubview(aliasInput)
    aliasInput.placeholder = localizable("input_noteName")
    NSLayoutConstraint.activate([
      aliasInput.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      aliasInput.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      aliasInput.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
      aliasInput.heightAnchor.constraint(equalToConstant: 50),
    ])
    if let alias = user?.alias {
      aliasInput.text = alias
    }
  }

  func saveAlias() {
//        guard let alais = aliasInput.text, alais.count > 0 else {
//            view.makeToast("请填写备注名", duration: 2, position: .center)
//            return
//        }
    if let text = aliasInput.text,
       text.count > 0,
       text.trimmingCharacters(in: .whitespaces).isEmpty {
      view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
      aliasInput.text = ""
      return
    }
    user?.alias = aliasInput.text
    if let u = user {
      view.makeToastActivity(.center)
      weak var weakSelf = self
      viewmodel.update(u) { error in
        NELog.infoLog(
          "ContactRemakNameViewController",
          desc: "CALLBACK update " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.view.makeToast(
            err.localizedDescription,
            duration: 2,
            position: .center
          )
        } else {
          if let block = weakSelf?.completion {
            block(u)
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
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

  public func textFieldChange() {
    guard let _ = aliasInput.markedTextRange else {
      if let text = aliasInput.text,
         text.count > textLimit {
        aliasInput.text = String(text.prefix(textLimit))
      }
      return
    }
  }
}
