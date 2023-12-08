
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEQChatKit
import NIMSDK
import UIKit

public class QChatMessageFrame: NSObject {
  // 是否显示时间
  public var showTime: Bool = false
  // 具体时间
  public var time: String? {
    didSet {
      setFrame()
    }
  }

  // 是否显示头像
  public var showAvatar: Bool = true
  // 用户头像地址
  public var avatar: String?
  // nickname
  public var nickname: String?
  // 发送者是否为自己
//    public var isSender:Bool?
  // 时间frame
  public var timeFrame: CGRect = .zero
  // 头像frame
  public var headFrame: CGRect?
  // 内容 size
  public var contentSize = CGSize.zero
  // 内容背景 frame
  public var contentFrame: CGRect?
  // cell整体高度
  public var cellHeight: CGFloat = 0.0
  // X初始位置
  public var startX: CGFloat = 0.0
  // 是否在播放音频
  public var isPlaying: Bool = false
  // 音频时间
  public var duration = 0

  public var attributeStr: NSAttributedString?

  public var isFromLocalCache = false

  // 消息是否已撤回
  public var isRevoked: Bool = false
  // 撤回消息的原始文案
  public var revokeText: String?

  // 是否允许快捷评论
  public var enableQuickComment: Bool = true {
    didSet {
      setFrame()
    }
  }

  // 快捷评论 frame
  public var quickCommentsFrame = CGRect.zero
  // 评论数量 label 的宽度列表，用于动态设置 collection cell 的宽度
  public var quickCommentCountWidth = [Int: CGFloat]()
  // 快捷评论
  public var quickComments: [NIMQChatMessageQuickCommentsDetail]? {
    didSet {
      setFrame()
    }
  }

  public var message: NIMQChatMessage? {
    didSet {
      setFrame()
    }
  }

  /// 根据消息内容计算并设置 frame
  public func setFrame() {
    guard let msg = message else {
      return
    }

    setRevokeMessage(message: msg)

    if isRevoked {
      getContentSize()
    } else {
      switch msg.messageType {
      case .text: // 计算文本
        getContentSize()
      case .image: // 计算图片类型
        if let imageObject = msg.messageObject,
           imageObject.isKind(of: NIMImageObject.self) {
          let obj = (imageObject as! NIMImageObject)
          contentSize = QChatMessageHelper.getSizeWithMaxSize(
            qChat_pic_size,
            size: obj.size,
            miniWH: qChat_min_h
          )
        } else {
          contentSize = qChat_pic_size
        }
      case .audio:
        var audioW = 80.0
        // contentSize
        let audioTotalWidth = 265.0
        if let obj = msg.messageObject as? NIMAudioObject {
          duration = obj.duration / 1000
          if duration > 2 {
            audioW = min(Double(duration) * 8 + audioW, audioTotalWidth)
          }
          contentSize = CGSize(width: audioW, height: qChat_min_h)
        }
      default:
        print("others")
      }
    }

    // 计算时间
    if showTime {
      timeFrame = CGRect(x: 0, y: qChat_margin, width: kScreenWidth, height: qChat_timeCellH)
    }

    // 计算头像
    var headFrameX = qChat_cell_margin
    let headFrameY = qChat_margin

    guard let msg = message else {
      return
    }

    if msg.isOutgoingMsg { // 消息发送者
      headFrameX = kScreenWidth - headFrameX - qChat_headWH
    }
    headFrame = CGRect(
      x: headFrameX,
      y: headFrameY +
        (timeFrame.height > 0 ? timeFrame.height + qChat_margin : 0),
      width: qChat_headWH,
      height: qChat_headWH
    )

    // 快捷评论区的宽高
    var quickCommentWidth: CGFloat?
    var quickComentHeight: CGFloat = 0
    if quickComments?.isEmpty == false {
      quickCommentWidth = enableQuickComment ? 30.0 : 0.0 // 添加表情按钮的宽度为30
      var tempWidth = quickCommentWidth! // 用于计算评论区行数
      var quickCommentMaxW = qChat_content_maxW // 评论区的最大宽度

      if msg.messageType == .text, contentSize.height > qChat_min_h {
        // 文本大于一行，则评论区的最大宽度取文本的最大宽度（文本的最大宽度不一定是 qChat_content_maxW）
        quickCommentMaxW = contentSize.width
      }
      quickCommentCountWidth = [Int: CGFloat]()
      for quickComment in quickComments! {
        if quickComment.count > 0 {
          let font: UIFont = quickComment.selfReplyed ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 16, weight: .medium)
          let countLabel = QChatMessageHelper.getCountLabel(quickComment.count)
          let size = countLabel.finalSize(font, CGSize(width: CGFloat(MAXFLOAT), height: 16))
          quickCommentCountWidth[quickComment.replyType] = size.width
          quickCommentWidth! += size.width + 40.0
          tempWidth += size.width + 40.0
          if tempWidth - 4 > quickCommentMaxW {
            // 长度大于内容最大宽度，需要另起一行
            quickComentHeight += 1
            tempWidth = size.width + 40.0
          }
        }
      }
      quickComentHeight = (quickComentHeight + 1) * (26 + 4) - 4
      quickCommentWidth = min(quickCommentWidth!, quickCommentMaxW)
    }

    var viewX = headFrame!.maxX + qChat_margin
    if msg.isOutgoingMsg { // 消息发送者
      let contentMaxW = max(quickCommentWidth ?? 0, contentSize.width)
      viewX = headFrameX - 3 * qChat_margin - contentMaxW
    }

    // 快捷评论区的frame
    if let width = quickCommentWidth, width > 0 {
      quickCommentsFrame = CGRect(
        x: viewX + qChat_margin,
        y: contentSize.height +
          3 * qChat_margin + (timeFrame.height > 0 ? timeFrame.height + qChat_margin : 0),
        width: width,
        height: quickComentHeight
      )
    } else {
      quickCommentsFrame = CGRect.zero
    }

    // 聊天气泡的frame
    contentFrame = CGRect(
      x: viewX,
      y: qChat_margin +
        (timeFrame.height > 0 ? timeFrame.height + qChat_margin : 0),
      width: max(contentSize.width, quickCommentsFrame.width) + 2 * qChat_margin,
      height: contentSize.height + 2 * qChat_margin +
        (quickCommentsFrame.height > 0 ? quickCommentsFrame.height + qChat_margin : 0)
    )

    // cell 高度
    cellHeight = contentFrame!.height + qChat_margin +
      (timeFrame.height > 0 ? timeFrame.height + qChat_margin : 0)

    // 单行文本
    if msg.messageType == .text || msg.messageType == .audio, contentSize.height <= qChat_min_h {
      if let height = contentFrame?.size.height {
        contentFrame?.size.height = height - qChat_margin * 2
      }
      quickCommentsFrame.origin = CGPoint(x: quickCommentsFrame.origin.x, y: quickCommentsFrame.origin.y - qChat_margin * 2)
      cellHeight -= qChat_margin * 2
    }

    // 根据发送者还是接收者判断起始x值
    if message?.isOutgoingMsg == true {
      startX = contentFrame!.width - contentSize.width - qChat_margin
    } else {
      startX = qChat_margin
    }
  }

  /// 计算文本消息的宽高
  /// - Parameter contentSize: 根据文案计算的宽高
  func getContentSize() {
    attributeStr = NEEmotionTool.getAttWithStr(
      str: message?.text ?? "",
      font: DefaultTextFont(16)
    )

    contentSize = attributeStr!.finalSize(DefaultTextFont(16), CGSize(width: qChat_content_maxW - qChat_margin * 2, height: CGFloat.greatestFiniteMagnitude))

    if contentSize.height < qChat_min_h { // 小于一行高度，就保持一行
      contentSize.height = qChat_min_h
    }
  }

  // 是否是撤回的消息，如果是则顺带返回撤回消息内容
  func setRevokeMessage(message: NIMQChatMessage) {
    let (isRevoke, content) = QChatMessageHelper.isRevokeMessage(message: message)
    if isRevoke {
      isRevoked = true
      revokeText = content
      message.text = localizable("message_recalled")
    }
  }
}
