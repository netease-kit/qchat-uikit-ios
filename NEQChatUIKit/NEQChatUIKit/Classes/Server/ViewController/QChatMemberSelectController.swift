
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECommonKit
import NECommonUIKit
import NECoreQChatKit
import NEQChatKit
import UIKit

typealias SelectMemeberCompletion = ([QChatUserInfo]) -> Void
typealias FilterMembersBlock = ([QChatUserInfo]) -> [QChatUserInfo]?

public protocol QChatMemberSelectControllerDelegate: NSObjectProtocol {
  func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void)
}

// enum SelectType {
//    case ServerMember
//    case ChannelMember
// }

public class QChatMemberSelectController: NEBaseTableViewController, MemberSelectViewModelDelegate,
  UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource,
  ViewModelDelegate {
  let viewmodel = QChatMemberSelectViewModel()
  var filterBlock: FilterMembersBlock?
  var completion: SelectMemeberCompletion?

//    var selectType =  SelectType.ServerMember

  var serverId: UInt64?

  var limit = 10

  private let tag = "QChatMemberSelectController"

  public weak var delegate: QChatMemberSelectControllerDelegate?

  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("noMember_add"), frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  lazy var collection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collect = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collect.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    return collect
  }()

  var collectionHeight: NSLayoutConstraint?

  var selectArray = [QChatUserInfo]()

  override public func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.delegate = self
    loadData()
    initializeConfig()
    setupUI()
  }

  func initializeConfig() {
    edgesForExtendedLayout = []
    title = localizable("qchat_select")
    addRightAction(localizable("qchat_sure"), #selector(sureClick), self)

    navigationView.setMoreButtonTitle(localizable("qchat_sure"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(sureClick))
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
  }

  func setupUI() {
    view.addSubview(collection)
    collection.delegate = self
    collection.dataSource = self
    collection.allowsMultipleSelection = false
    collection.translatesAutoresizingMaskIntoConstraints = false
    collectionHeight = collection.heightAnchor.constraint(equalToConstant: 0)
    collectionHeight?.isActive = true
    collection.backgroundColor = UIColor(hexString: "F2F4F5")
    NSLayoutConstraint.activate([
      collection.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      collection.leftAnchor.constraint(equalTo: view.leftAnchor),
      collection.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    collection.register(
      QChatUserUnCheckCell.self,
      forCellWithReuseIdentifier: "\(NSStringFromClass(QChatUserUnCheckCell.self))"
    )

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: collection.bottomAnchor),
    ])
    if #available(iOS 13.0, *) {
      tableView.automaticallyAdjustsScrollIndicatorInsets = false
    } else {
      // Fallback on earlier versions
    }
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatSelectedCell.self,
      forCellReuseIdentifier: "\(QChatSelectedCell.self)"
    )

    if #available(iOS 11.0,*) {
      tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior
        .never
    } else {
      automaticallyAdjustsScrollViewInsets = false
    }
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
//        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(loadData))

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  @objc func sureClick() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      view.makeToast(localizable("network_error"), duration: 2, position: .center)
      return
    }

    if selectArray.count <= 0 {
      view.makeToast(localizable("qchat_not_empty_select_memeber"))
      return
    }

    if let block = completion {
      block(selectArray)
    }
    navigationController?.popViewController(animated: true)
  }

  @objc func loadData() {
    viewmodel.loadFirst(serverId: serverId) { [weak self] error, users in
      NELog.infoLog(
        ModuleName + " " + (self?.tag ?? "QChatMemberSelectController"),
        desc: "CALLBACK loadFirst " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
      } else {
        if (users?.count ?? 0) <= 0 {
          self?.emptyView.isHidden = false
          return
        }
        self?.tableView.reloadData()
        self?.tableView.mj_footer?.resetNoMoreData()
        self?.tableView.mj_header?.endRefreshing()
      }
    }
  }

  @objc func loadMoreData() {
    viewmodel.loadMore(serverId: serverId) { [weak self] error, users in
      NELog.infoLog(
        ModuleName + " " + (self?.tag ?? "QChatMemberSelectController"),
        desc: "CALLBACK loadMore " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
      } else {
        if users?.count ?? 0 > 0 {
          self?.tableView.reloadData()
          self?.tableView.mj_footer?.endRefreshing()
        } else {
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        }
      }
    }
  }

  // MARK:

  public func dataDidError(_ error: Error) {
    if let err = error as NSError? {
      switch err.code {
      case errorCode_NetWorkError:
        showToast(localizable("network_error"))
      case errorCode_NoPermission:
        showToast(localizable("no_permession"))
      default:
        showToast(err.localizedDescription)
      }
    }
  }

  public func dataDidChange() {
    tableView.reloadData()
  }

  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    selectArray.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let user = selectArray[indexPath.row]
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(NSStringFromClass(QChatUserUnCheckCell.self))",
      for: indexPath
    ) as? QChatUserUnCheckCell
    cell?.configure(user)
    return cell ?? UICollectionViewCell()
  }

  public func collectionView(_ collectionView: UICollectionView,
                             didSelectItemAt indexPath: IndexPath) {
    let user = selectArray[indexPath.row]
    didUnselectContact(user)
  }

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 46, height: 52)
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel.datas.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: QChatSelectedCell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatSelectedCell.self)",
      for: indexPath
    ) as! QChatSelectedCell
    let user = viewmodel.datas[indexPath.row]
    cell.user = user
    return cell
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    62
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let user = viewmodel.datas[indexPath.row]
    let cell = tableView.cellForRow(at: indexPath) as? QChatSelectedCell

    if user.select == true {
      cell?.setUnselect()
      didUnselectContact(user)
    } else {
      if selectArray.count >= limit {
        // view.makeToast("超出\(limit)人限制")
        let toastContent = String(format: localizable("qchat_select_limit"), limit)
        showToast(toastContent)
        return
      }
      cell?.setSelect()
      didSelectContact(user)
    }
    //        tableView.reloadRows(at: [indexPath], with: .none)
  }

  func didSelectContact(_ user: QChatUserInfo) {
    user.select = true
    if selectArray.contains(where: { c in
      user === c
    }) == false {
      selectArray.append(user)
      if let height = collectionHeight?.constant, height <= 0 {
        collectionHeight?.constant = 52
      }
    }
    collection.reloadData()
    tableView.reloadData()
    refreshSelectCount()
  }

  func didUnselectContact(_ user: QChatUserInfo) {
    user.select = false
    selectArray.removeAll { c in
      user === c
    }
    if selectArray.count <= 0 {
      collection.reloadData()
      collectionHeight?.constant = 0
    }
    collection.reloadData()
    tableView.reloadData()
    refreshSelectCount()
  }

  func refreshSelectCount() {
    if selectArray.count > 0 {
      let str = "\(localizable("qchat_sure"))(\(selectArray.count))"
      rightNavBtn.setTitle(str, for: .normal)
      navigationView.setMoreButtonTitle(str)
    } else {
      rightNavBtn.setTitle(localizable("qchat_sure"), for: .normal)
      navigationView.setMoreButtonTitle(localizable("qchat_sure"))
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  //    MARK: MemberSelectViewModelDelegate

  public func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
    //        查询需要筛选的用户
    delegate?.filterMembers(accid: accid, filterMembers)
  }
}
