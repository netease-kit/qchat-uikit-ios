
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NECoreQChatKit
import NIMSDK
import NIMQChat
import UIKit

@objc class QChatBubbleButton: UIButton {
  // 设置气泡背景图片
  public func setBubbleImage(image: UIImage) {
    let image = image
      .resizableImage(withCapInsets: UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25))
    setBackgroundImage(image, for: .normal)
    setBackgroundImage(image, for: .highlighted)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    imageView?.contentMode = .scaleAspectFill
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
//    //设置气泡背景色
//    public func setBubbleImage(color:UIColor){
//        let image = self.currentBackgroundImage
//    }
}

enum QChatMessageClickType: String {
  case message
  case LongPressMessage
  case head
  case retry
}

protocol QChatBaseCellDelegate: NSObjectProtocol {
  // click action
  func didSelectWithCell(cell: QChatBaseTableViewCell, type: QChatMessageClickType,
                         message: NIMQChatMessage)

  func didClickHeader(_ message: NIMQChatMessage)
  func didLongPress(_ cell: UITableViewCell, _ messageFrame: QChatMessageFrame?)

  // 单击重新编辑按钮
  func didTapReeditButton(_ cell: UITableViewCell, _ messageFrame: QChatMessageFrame?)

  // 点击表情评论
  func didClickEmojiComment(_ type: Int, _ cell: UITableViewCell, _ messageFrame: QChatMessageFrame?)
}

@objcMembers
class QChatBaseTableViewCell: UITableViewCell {
  weak var delegate: QChatBaseCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  public var messageFrame: QChatMessageFrame? {
    didSet {
      timeLabel.frame = messageFrame?.timeFrame ?? CGRect.zero
      btnHeadImage.frame = messageFrame?.headFrame ?? CGRect.zero
      contentBtn.frame = messageFrame?.contentFrame ?? CGRect.zero
      quickCommentCollection.frame = messageFrame?.quickCommentsFrame ?? CGRect.zero

      if #available(iOS 13, *) {
        DispatchQueue.main.async {
          self.quickCommentCollection.reloadData()
        }
      } else {
        quickCommentCollection.reloadData()
      }

      timeLabel.text = messageFrame?.time

      // 头像赋值
      if let icon = messageFrame?.avatar {
        btnHeadImage.setTitle("")
        btnHeadImage.sd_setImage(with: URL(string: icon), completed: nil)
      } else {
        if let sendName = messageFrame?.message?.senderName {
          btnHeadImage.setTitle(sendName)
        } else {
          btnHeadImage.setTitle(messageFrame?.message?.from ?? "")
        }
        btnHeadImage.sd_setImage(with: nil, completed: nil)
        btnHeadImage.backgroundColor = UIColor.colorWithNumber(number: 0)
      }

      guard let msg = messageFrame?.message else {
        return
      }

      if msg.isOutgoingMsg {
        contentBtn
          .setBubbleImage(image: UIImage.ne_imageNamed(name: "chat_message_send")!)
        // 设置消息状态 判断消息发送是否成功

        activityView.frame = CGRect(
          x: contentBtn.left - (5 + 20),
          y: contentBtn.top + (contentBtn.height - 20) / 2,
          width: 20,
          height: 20
        )

        if msg.deliveryState == NIMMessageDeliveryState.deliveried.rawValue || messageFrame?.isFromLocalCache == true {
          activityView.messageStatus = .successed
        } else if msg.deliveryState == NIMMessageDeliveryState.delivering.rawValue {
          activityView.messageStatus = .sending
        } else {
          activityView.messageStatus = .failed
        }

      } else {
        activityView.isHidden = true
        contentBtn
          .setBubbleImage(image: UIImage.ne_imageNamed(name: "chat_message_receive")!)
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.backgroundColor = .white
    addContentSubviews()
    addGesture()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func addContentSubviews() {
    contentView.addSubview(timeLabel)
    contentView.addSubview(btnHeadImage)
    contentView.addSubview(contentBtn)
    contentView.addSubview(activityView)
    contentView.addSubview(quickCommentCollection)
  }

  func addGesture() {
    let messageLongTap = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    contentBtn.addGestureRecognizer(messageLongTap)

    let emotionLongTap = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    quickCommentCollection.addGestureRecognizer(emotionLongTap)
  }

  override func draw(_ rect: CGRect) {
    btnHeadImage.addCorner(conrners: .allCorners, radius: 16)
  }

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = DefaultTextFont(12)
    label.textColor = UIColor.ne_emptyTitleColor
    label.textAlignment = .center
    return label
  }()

  private lazy var btnHeadImage: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    let tap = UITapGestureRecognizer()
    view.addGestureRecognizer(tap)
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1
    tap.addTarget(self, action: #selector(headerClick))
    return view
  }()

  public lazy var contentBtn: QChatBubbleButton = {
    let btn = QChatBubbleButton(frame: .zero)
    btn.addTarget(self, action: #selector(bubbleClick), for: .touchUpInside)
    return btn
  }()

  public lazy var activityView: QChatActivityIndicatorView = {
    let activityView = QChatActivityIndicatorView()
    activityView.isHidden = true
    return activityView
  }()

  // 快捷（表情）评论区
  public lazy var quickCommentCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .vertical
    flow.minimumLineSpacing = 4
    flow.minimumInteritemSpacing = 4
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false

    collection.register(
      QChatEmojiCommentCell.self, forCellWithReuseIdentifier: "\(QChatEmojiCommentCell.self)"
    )
    return collection
  }()
}

extension QChatBaseTableViewCell {
  @objc func bubbleClick(sender: UIButton) {
    if let message = messageFrame?.message {
      delegate?.didSelectWithCell(cell: self, type: .message, message: message)
    }
  }

  @objc func headerClick() {
    NELog.infoLog("chat base cell", desc: "header click")
    if let message = messageFrame?.message {
      delegate?.didClickHeader(message)
    }
  }

  @objc func longPress(longPress: UILongPressGestureRecognizer) {
    switch longPress.state {
    case .began:
      delegate?.didLongPress(self, messageFrame)
    default:
      break
    }
  }
}

extension QChatBaseTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let commentsCount = messageFrame?.quickComments?.count, commentsCount > 0 {
      if messageFrame?.enableQuickComment == false {
        // 无表情评论权限
        return commentsCount
      }
      // 将【添加表情】按钮计入总数量
      return commentsCount + 1
    }
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(QChatEmojiCommentCell.self)",
      for: indexPath
    ) as! QChatEmojiCommentCell

    var indexRow = indexPath.row - 1
    if messageFrame?.enableQuickComment == false {
      // 无表情评论权限
      indexRow = indexPath.row
    }

    if indexRow == -1 {
      cell.imageView.image = UIImage.ne_imageNamed(name: "add_emoji")
      cell.removeCountLabel()
    } else if indexRow < messageFrame?.quickComments?.count ?? 0,
              let type = messageFrame?.quickComments?[indexRow].replyType {
      let imageName = String(format: "emoji_%03d", type - 1)
      let image = UIImage.ne_bundleImage(name: imageName)
      cell.imageView.image = image
      if let quickComment = messageFrame?.quickComments?[indexRow],
         let width = messageFrame?.quickCommentCountWidth[quickComment.replyType] {
        if quickComment.count > 0, width > 0 {
          cell.addCountLabel(QChatMessageHelper.getCountLabel(quickComment.count), width: width)
          cell.setCountLabel(highlight: quickComment.selfReplyed)
        }
      }
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    var indexRow = indexPath.row - 1
    if messageFrame?.enableQuickComment == false {
      // 无表情评论权限
      indexRow = indexPath.row
    }

    if indexRow == -1 {
      // 点击了【添加表情】按钮
      delegate?.didClickEmojiComment(-1, self, messageFrame)
    } else if let type = messageFrame?.quickComments?[indexRow].replyType {
      delegate?.didClickEmojiComment(type, self, messageFrame)
    }
  }

  // UICollectionViewDelegateFlowLayout
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    var indexRow = indexPath.row - 1
    if messageFrame?.enableQuickComment == false {
      // 无表情评论权限
      indexRow = indexPath.row
    }

    if indexRow == -1 {
      // 【添加表情】按钮的长宽固定为 30
      return CGSize(width: 26, height: 26)
    } else if indexRow < messageFrame?.quickComments?.count ?? 0,
              let quickComment = messageFrame?.quickComments?[indexRow],
              let typeCountWidth = messageFrame?.quickCommentCountWidth[quickComment.replyType], typeCountWidth > 0 {
      return CGSize(width: 36 + typeCountWidth, height: 26)
    } else {
      return CGSize(width: 56, height: 26)
    }
  }
}
