//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECommonKit
import UIKit

@objcMembers
open class QChatSquareViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, QChatSquareViewModelDelegate {
  public var delegate: SquareDataSourceDelegate?

  public let viewmodel = QChatSquareViewModel()

  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "no_data", content: localizable("empty_data"), frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthConstraint?.constant = 122
    view.heightConstraint?.constant = 91
    view.isHidden = true
    return view
  }()

  public var type = 0
  // collection view
  lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 7.0
    layout.minimumInteritemSpacing = 7.0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.showsVerticalScrollIndicator = false
    collection.showsHorizontalScrollIndicator = false
    collection.alwaysBounceVertical = true
    collection.delegate = self
    collection.dataSource = self
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(refreshData)
    )
    return collection
  }()

  // 内容区缺省占位图
  public let contentLoadingImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "square_content_empty"))
    imageView.contentMode = .scaleToFill
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  var leftCellWidth: CGFloat = 0
  var rightCellWidth: CGFloat = 0

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    // 随机背景颜色
//        view.backgroundColor = UIColor(red: CGFloat.random(in: 0...1),
//                                       green: CGFloat.random(in: 0...1),
//                                       blue: CGFloat.random(in: 0...1),
//                                       alpha: 1.0)
    view.backgroundColor = .clear
    viewmodel.delegate = self

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: view.topAnchor),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    view.addSubview(contentLoadingImageView)
    NSLayoutConstraint.activate([
      contentLoadingImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      contentLoadingImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      contentLoadingImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 18),
      contentLoadingImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -18),
    ])

    collectionView.register(QChatSquareCollectionViewCell.self, forCellWithReuseIdentifier: QChatSquareCollectionViewCell.className())

    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
    ])

    let screenWidth = UIScreen.main.bounds.width
    leftCellWidth = ceil((screenWidth - 16.0 * 2 - 8.0) / 2.0)
    rightCellWidth = screenWidth - 16.0 * 2 - 8.0 - leftCellWidth

    refreshData()
  }

  func refreshData() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      view.makeToast(localizable("network_error"), duration: 2, position: .center)
      collectionView.mj_header?.endRefreshing()
      contentLoadingImageView.isHidden = true
      if viewmodel.datas.count <= 0 {
        emptyView.isHidden = false
      }
      collectionView.mj_header?.endRefreshing()
      return
    }

    weak var weakSelf = self

    delegate?.requestServerInfoForSearchType(type) { squareServers, error in
      if let err = error {
        weakSelf?.view.makeToast(err.localizedDescription)
        weakSelf?.collectionView.mj_header?.endRefreshing()
        weakSelf?.contentLoadingImageView.isHidden = true
        if weakSelf?.viewmodel.datas.count ?? 0 <= 0 {
          weakSelf?.emptyView.isHidden = false
        }

        return
      }
      if squareServers.count <= 0 {
        weakSelf?.viewmodel.datas.removeAll()
        weakSelf?.collectionView.mj_header?.endRefreshing()
        weakSelf?.contentLoadingImageView.isHidden = true
        weakSelf?.emptyView.isHidden = false
        weakSelf?.collectionView.reloadData()
        return
      }
      weakSelf?.viewmodel.checkJoinServer(servers: squareServers) { error in
        weakSelf?.collectionView.mj_header?.endRefreshing()
        if let err = error {
          weakSelf?.view.makeToast(err.localizedDescription)
          return
        }
        weakSelf?.contentLoadingImageView.isHidden = true
        weakSelf?.viewmodel.datas.removeAll()
        if squareServers.count > 0 {
          squareServers.forEach { server in
            weakSelf?.viewmodel.datas.append(server)
          }
          weakSelf?.emptyView.isHidden = true
        } else {
          weakSelf?.emptyView.isHidden = false
        }
        weakSelf?.collectionView.reloadData()
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

  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QChatSquareCollectionViewCell.className(), for: indexPath) as! QChatSquareCollectionViewCell

    let server = viewmodel.datas[indexPath.row]
    cell.configureData(server: server)
    return cell
  }

  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    viewmodel.datas.count
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      view.makeToast(localizable("network_error"), duration: 2, position: .center)
      return
    }
    let server = viewmodel.datas[indexPath.row]
    delegate?.didSelectSquareServer(server: server)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    // 根据 indexPath 返回对应 item 的大小
    if indexPath.row % 2 == 0 {
      return CGSize(width: leftCellWidth, height: 224)
    } else {
      return CGSize(width: rightCellWidth, height: 224)
    }
  }

  public func didNeedRefreshData() {
    collectionView.reloadData()
  }
}
