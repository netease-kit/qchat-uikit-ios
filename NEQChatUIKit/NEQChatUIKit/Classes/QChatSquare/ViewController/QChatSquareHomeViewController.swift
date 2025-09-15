// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit

import UIKit

public protocol SquareDataSourceDelegate: NSObjectProtocol {
  // 获取广场顶部Tab数据回调协议
  func requestSquareSearchType(_ completion: @escaping ([QChatSquarePageInfo], NSError?) -> Void)
  // 获取广场tab下对应的广场列表数据
  func requestServerInfoForSearchType(_ searchType: Int, _ completion: @escaping ([QChatSquareServer], NSError?) -> Void)
  // 具体点击广场的回调
  func didSelectSquareServer(server: QChatSquareServer)
}

@objcMembers
open class QChatSquareHomeViewController: UIViewController, NEPagingContentViewControllerDataSource, NETabPagingMenuViewControllerDataSource, NETabPagingMenuViewControllerDelegate, NEPagingContentViewControllerDelegate {
  public var menuViewController = NETabPagingMenuViewController()
  public var contentViewController = NEPagingContentViewController()

  public weak var delegate: SquareDataSourceDelegate?

  public let focusView = NEUnderlineFocusView()

  public let viewmodel = QChatSquareHomeViewModel()

  // 顶部缺省展位图
  public let tabLoadingImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "square_tab_empty"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleToFill
    return imageView
  }()

  // 内容区缺省占位图
  public let contentLoadingImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "square_content_empty"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleToFill
    return imageView
  }()

  var dataSource = [(menu: String, content: UIViewController)]()

  lazy var firstLoad: (() -> Void)? = { [weak self, menuViewController, contentViewController] in
    menuViewController.reloadData()
    contentViewController.reloadData { [weak self] in
      self?.adjustfocusViewWidth(index: 0, percent: 0)
    }
    self?.firstLoad = nil
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    weak var weakSelf = self
    delegate?.requestSquareSearchType { infos, error in
      if let err = error {
        self.view.makeToast(err.localizedDescription)
        return
      }
      weakSelf?.tabLoadingImageView.isHidden = true
      weakSelf?.contentLoadingImageView.isHidden = true
      for info in infos {
        let vc = QChatSquareViewController()
        vc.type = info.type
        vc.delegate = weakSelf?.delegate
        weakSelf?.dataSource.append((menu: info.title, content: vc))
      }
      if infos.count > 0 {
        weakSelf?.setupUI()
      }
    }
    setupLoadingUI()
    // Do any additional setup after loading the view.
  }

  func setupLoadingUI() {
    view.backgroundColor = .ne_navLineColor
    view.addSubview(tabLoadingImageView)
    view.addSubview(contentLoadingImageView)
    NSLayoutConstraint.activate([
      tabLoadingImageView.heightAnchor.constraint(equalToConstant: 22),
      tabLoadingImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 18),
      tabLoadingImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -18),
      tabLoadingImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
    ])

    NSLayoutConstraint.activate([
      contentLoadingImageView.leftAnchor.constraint(equalTo: tabLoadingImageView.leftAnchor),
      contentLoadingImageView.rightAnchor.constraint(equalTo: tabLoadingImageView.rightAnchor),
      contentLoadingImageView.topAnchor.constraint(equalTo: tabLoadingImageView.bottomAnchor, constant: 22),
      contentLoadingImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = true
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.isHidden = false
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  func setupUI() {
    addChild(contentViewController)
    addChild(menuViewController)
    view.addSubview(contentViewController.view)
    view.addSubview(menuViewController.view)
    contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
    menuViewController.view.translatesAutoresizingMaskIntoConstraints = false
    menuViewController.dataSource = self
    menuViewController.delegate = self
    menuViewController.view.backgroundColor = .clear

    contentViewController.dataSource = self
    contentViewController.delegate = self
    NSLayoutConstraint.activate([
      menuViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 18),
      menuViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
      menuViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
      menuViewController.view.heightAnchor.constraint(equalToConstant: 30),

      contentViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      contentViewController.view.topAnchor.constraint(equalTo: menuViewController.view.bottomAnchor),

    ])
    menuViewController.register(type: NETitleLabelMenuViewCell.self, forCellWithReuseIdentifier: "identifier")
    menuViewController.registerFocusView(view: focusView)
    contentViewController.scrollView.bounces = true
    NEPagingKitConfig.focusColor = UIColor(hexString: "#337EFF")
    NEPagingKitConfig.normalColor = UIColor(hexString: "#6E6F74")
    NEPagingKitConfig.menuTitleFont = UIFont.systemFont(ofSize: 16.0)
    focusView.underlineHeight = 2.0
    focusView.underlineColor = UIColor(hexString: "#337EFF")
    firstLoad?()
  }

  public func menuViewController(viewController: NETabPagingMenuViewController, cellForItemAt index: Int) -> NEPagingMenuViewCell {
    let cell = viewController.dequeueReusableCell(withReuseIdentifier: "identifier", for: index) as! NETitleLabelMenuViewCell
    cell.titleLabel.text = dataSource[index].menu
    return cell
  }

  public func menuViewController(viewController: NETabPagingMenuViewController, widthForItemAt index: Int) -> CGFloat {
    68
  }

  var insets: UIEdgeInsets {
    if #available(iOS 11.0, *) {
      return view.safeAreaInsets
    } else {
      return .zero
    }
  }

  public func numberOfItemsForMenuViewController(viewController: NETabPagingMenuViewController) -> Int {
    dataSource.count
  }

  public func menuViewController(viewController: NETabPagingMenuViewController, didSelect page: Int, previousPage: Int) {
    contentViewController.scroll(to: page, animated: true)
  }

  public func menuViewController(viewController: NETabPagingMenuViewController, willAnimateFocusViewTo index: Int, with coordinator: PagingMenuFocusViewAnimationCoordinator) {
    setFocusViewWidth(index: index)
    coordinator.animateFocusView { [weak self] coordinator in
      self?.focusView.layoutIfNeeded()
    } completion: { _ in }
  }

  public func numberOfItemsForContentViewController(viewController: NEPagingContentViewController) -> Int {
    dataSource.count
  }

  public func contentViewController(viewController: NEPagingContentViewController, viewControllerAt index: Int) -> UIViewController {
    dataSource[index].content
  }

  public func contentViewController(viewController: NEPagingContentViewController, didManualScrollOn index: Int, percent: CGFloat) {
    menuViewController.scroll(index: index, percent: percent, animated: false)
    adjustfocusViewWidth(index: index, percent: percent)
  }

  // TODO: - needs refactering
  func adjustfocusViewWidth(index: Int, percent: CGFloat) {
    let adjucentIdx = percent < 0 ? index - 1 : index + 1
    guard let currentCell = menuViewController.cellForItem(at: index) as? NETitleLabelMenuViewCell,
          let adjucentCell = menuViewController.cellForItem(at: adjucentIdx) as? NETitleLabelMenuViewCell else {
      return
    }
    focusView.underlineWidth = adjucentCell.calcIntermediateLabelSize(with: currentCell, percent: percent)
    focusView.underlineWidth = 22
  }

  // TODO: - needs refactering
  func setFocusViewWidth(index: Int) {
    guard let cell = menuViewController.cellForItem(at: index) as? NETitleLabelMenuViewCell else {
      return
    }
    focusView.underlineWidth = 22
  }
}
