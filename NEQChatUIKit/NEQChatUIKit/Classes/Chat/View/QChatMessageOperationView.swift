
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

public protocol QChatMessageOperationViewDelegate: AnyObject {
  func didSelectedItem(item: QChatOperationItem)
  func didSelectedEmoji(emoji: NIMInputEmoticon)
}

@objcMembers
open class QChatMessageOperationView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
  public weak var delegate: QChatMessageOperationViewDelegate?
  public var items = [QChatOperationItem]() {
    didSet {
      operationCollection.reloadData()
    }
  }

  // 固定的快捷表情
  public var quickEmojiItems = [NIMInputEmoticon]()
  // 所有表情
  public var allEmojiItems = [NIMInputEmoticon]()
  // 表情资源
  public var emoticonCatalog: NIMInputEmoticonCatalog?
  // 显示消息操作项时的 frame 高度
  public var oldFrameHeight: CGFloat = 0
  // 是否显示表情回复
  public var showEmoji: Bool = false

  // 是否显示【更多表情】按钮
  public var showMoreButton = true {
    didSet {
      moreButton.isHidden = !showMoreButton
    }
  }

  // 更多表情是否展示在操作菜单下方
  public var viewUnderMessage = true

  public init(frame: CGRect, showEmoji: Bool = false) {
    super.init(frame: frame)
    self.showEmoji = showEmoji
    setupUI()

    let emoticonCatalog = NIMInputEmoticonManager.shared
      .emoticonCatalog(catalogID: NIMKit_EmojiCatalog)

    let emotionIds = QChatMessageHelper.quickEmojiIDList()

    setEmoticonCatalog(catalog: emoticonCatalog!, emotionIds)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // 快捷表情的背景view
  public lazy var emojiBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  // 【更多表情】按钮
  public lazy var moreButton: UIButton = {
    let moreButton = UIButton()
    moreButton.translatesAutoresizingMaskIntoConstraints = false
    moreButton.setImage(UIImage.ne_imageNamed(name: "more_emoji"), for: .normal)
    moreButton.setImage(UIImage.ne_imageNamed(name: "less_emoji"), for: .selected)
    moreButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
    moreButton.backgroundColor = .white
    return moreButton
  }()

  // 快捷表情
  public lazy var emojiCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.itemSize = CGSize(width: 48, height: 48)
    flow.scrollDirection = .vertical
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false

    collection.register(
      QChatEmojiCell.self, forCellWithReuseIdentifier: "\(QChatEmojiCell.self)"
    )
    return collection
  }()

  // 所有表情
  public lazy var emojiAllCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.itemSize = CGSize(width: 48, height: 46)
    flow.scrollDirection = .vertical
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false

    collection.register(
      QChatEmojiCell.self, forCellWithReuseIdentifier: "\(QChatEmojiCell.self)"
    )
    return collection
  }()

  // 消息操作项（撤回、删除...）
  public lazy var operationCollection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 30, height: 42)
    layout.minimumLineSpacing = 16.0
    layout.minimumInteritemSpacing = 37.5
    layout.scrollDirection = .vertical
    let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .white
    collection.translatesAutoresizingMaskIntoConstraints = false

    collection.dataSource = self
    collection.delegate = self
    collection.isUserInteractionEnabled = true

    collection.register(
      QChatOperationCell.self, forCellWithReuseIdentifier: "\(QChatOperationCell.self)"
    )
    return collection
  }()

  open func setupUI() {
    backgroundColor = .white
    layer.cornerRadius = 7
    layer.shadowOffset = CGSize(width: 0, height: 4)
    layer.shadowColor = UIColor.ne_operationBorderColor.cgColor
    layer.shadowOpacity = 0.25
    layer.shadowRadius = 7

    if showEmoji {
      emojiBackView.addSubview(emojiCollection)
      NSLayoutConstraint.activate([
        emojiCollection.leftAnchor.constraint(equalTo: emojiBackView.leftAnchor, constant: 7),
        emojiCollection.rightAnchor.constraint(equalTo: emojiBackView.rightAnchor, constant: -7),
        emojiCollection.centerYAnchor.constraint(equalTo: emojiBackView.centerYAnchor),
        emojiCollection.heightAnchor.constraint(equalToConstant: 48),
      ])

      emojiBackView.addSubview(moreButton)
      NSLayoutConstraint.activate([
        moreButton.rightAnchor.constraint(equalTo: emojiBackView.rightAnchor, constant: -7),
        moreButton.centerYAnchor.constraint(equalTo: emojiBackView.centerYAnchor),
        moreButton.widthAnchor.constraint(equalToConstant: 48),
        moreButton.heightAnchor.constraint(equalToConstant: 48),
      ])

      let line = UIView()
      line.translatesAutoresizingMaskIntoConstraints = false
      line.backgroundColor = UIColor(hexString: "#E4E9F2")
      emojiBackView.addSubview(line)
      NSLayoutConstraint.activate([
        line.leadingAnchor.constraint(equalTo: emojiBackView.leadingAnchor, constant: 16),
        line.trailingAnchor.constraint(equalTo: emojiBackView.trailingAnchor, constant: -16),
        line.bottomAnchor.constraint(equalTo: emojiBackView.bottomAnchor),
        line.heightAnchor.constraint(equalToConstant: 0.5),
      ])

      addSubview(emojiBackView)
      NSLayoutConstraint.activate([
        emojiBackView.leadingAnchor.constraint(equalTo: leadingAnchor),
        emojiBackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        emojiBackView.topAnchor.constraint(equalTo: topAnchor),
        emojiBackView.heightAnchor.constraint(equalToConstant: 56),
      ])
    }
    addSubview(operationCollection)
  }

  open func setEmoticonCatalog(catalog: NIMInputEmoticonCatalog, _ quickEmojis: [String]?) {
    emoticonCatalog = catalog
    allEmojiItems = catalog.emoticons ?? []
    if let emotionIds = quickEmojis {
      setQuickEmojis(emotionIds: emotionIds)
    }
  }

  open func setQuickEmojis(emotionIds: [String]) {
    quickEmojiItems = [NIMInputEmoticon]()
    emotionIds.forEach { name in
      if let emoticons = emoticonCatalog?.id2Emoticons?[name] {
        quickEmojiItems.append(emoticons)
      }
    }
  }

  open func setQuickEmojis(emotions: [NIMInputEmoticon]) {
    quickEmojiItems = emotions
  }

  open func showAllEmoji() {
    operationCollection.removeFromSuperview()
    addSubview(emojiAllCollection)
    NSLayoutConstraint.activate([
      emojiAllCollection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
      emojiAllCollection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
      emojiAllCollection.topAnchor.constraint(equalTo: emojiBackView.bottomAnchor, constant: 0),
      emojiAllCollection.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])

    // 操作菜单在消息上面
    if !viewUnderMessage {
      if showMoreButton {
        frame.origin = CGPoint(x: frame.origin.x, y: frame.origin.y - (254 - 18.0 - 58.0))
      }

      // 展开后超出导航栏下边界，则整体下移
      if frame.origin.y < NEConstant.navigationAndStatusHeight {
        let offSet = NEConstant.navigationAndStatusHeight - frame.origin.y
        frame.origin = CGPoint(x: frame.origin.x, y: frame.origin.y + offSet + qChat_margin)
        frame.size = CGSize(width: frame.width, height: 310)
      } else {
        frame.size = CGSize(width: frame.width, height: 310)
      }
    }
  }

  open func showOperation() {
    emojiAllCollection.removeFromSuperview()
    addSubview(operationCollection)
    NSLayoutConstraint.activate([
      operationCollection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25),
      operationCollection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25),
      operationCollection.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])

    if showEmoji {
      operationCollection.topAnchor.constraint(equalTo: emojiBackView.bottomAnchor, constant: 8).isActive = true
    } else {
      operationCollection.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    }
  }

  open func moreButtonAction() {
    moreButton.isSelected = !moreButton.isSelected
    if moreButton.isSelected {
      frame.size = CGSize(width: frame.width, height: 310)
      showAllEmoji()
    } else {
      if !viewUnderMessage {
        // 操作菜单在消息上面
        frame.origin = CGPoint(x: frame.origin.x, y: frame.origin.y + (254 - 18.0 - 58.0))
      }
      frame.size = CGSize(width: frame.width, height: oldFrameHeight)
      showOperation()
    }
  }

//    MARK: UICollectionViewDataSource

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    if collectionView == emojiAllCollection {
      return allEmojiItems.count
    } else if collectionView == emojiCollection {
      return quickEmojiItems.count
    } else {
      return items.count
    }
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if collectionView == emojiCollection {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "\(QChatEmojiCell.self)",
        for: indexPath
      ) as? QChatEmojiCell
      let image = UIImage.ne_bundleImage(name: quickEmojiItems[indexPath.row].fileName ?? "")
      cell?.imageView.image = image
      return cell ?? UICollectionViewCell()
    } else if collectionView == emojiAllCollection {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "\(QChatEmojiCell.self)",
        for: indexPath
      ) as? QChatEmojiCell
      let image = UIImage.ne_bundleImage(name: allEmojiItems[indexPath.row].fileName ?? "")
      cell?.imageView.image = image
      return cell ?? UICollectionViewCell()
    } else {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "\(QChatOperationCell.self)",
        for: indexPath
      ) as? QChatOperationCell
      cell?.model = items[indexPath.row]
      return cell ?? UICollectionViewCell()
    }
  }

//    MARK: UICollectionViewDelegate

  open func collectionView(_ collectionView: UICollectionView,
                           didSelectItemAt indexPath: IndexPath) {
    removeFromSuperview()
    if collectionView == emojiCollection {
      delegate?.didSelectedEmoji(emoji: quickEmojiItems[indexPath.row])
    } else if collectionView == emojiAllCollection {
      delegate?.didSelectedEmoji(emoji: allEmojiItems[indexPath.row])
    } else {
      delegate?.didSelectedItem(item: items[indexPath.row])
    }
  }
}
