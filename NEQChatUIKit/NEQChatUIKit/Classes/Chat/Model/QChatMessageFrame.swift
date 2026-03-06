
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEQChatKit
import NIMQChat
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
      case NIMMessageType.text.rawValue: // 计算文本
        getContentSize()
      case NIMMessageType.image.rawValue: // 计算图片类型
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
      case NIMMessageType.audio.rawValue:
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

      if msg.messageType == NIMMessageType.text.rawValue, contentSize.height > qChat_min_h {
        // 文本大于一行，则评论区的最大宽度取文本的最大宽度（文本的最大宽度不一定是 qChat_content_maxW）
        quickCommentMaxW = contentSize.width
      }
      quickCommentCountWidth = [Int: CGFloat]()
      for quickComment in quickComments! {
        if quickComment.count > 0 {
          let font: UIFont = quickComment.selfReplyed ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 16, weight: .medium)
          let countLabel = QChatMessageHelper.getCountLabel(quickComment.count)
          let size = String.getRealSize(countLabel, font, CGSize(width: CGFloat(MAXFLOAT), height: 16))
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
    if msg.messageType == NIMMessageType.text.rawValue || msg.messageType == NIMMessageType.audio.rawValue, contentSize.height <= qChat_min_h {
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
    let text = message?.text ?? ""
    let mutableAttrStr = NEEmotionTool.getAttWithStr(
      str: text,
      font: DefaultTextFont(16)
    )

    // 调试日志：打印 remoteExt 内容，便于排查 @ 高亮不工作的问题
    print("[QChatAt-Debug] getContentSize text='\(text)' remoteExt=\(String(describing: message?.remoteExt))")

    // 优先使用 remoteExt 中记录的精确范围高亮（可跨设备、历史消息）；
    // 若无 remoteExt（旧消息兼容），再退回到 mentionedAccids 判断 + RegEx 兜底。
    let didHighlight = highlightAtMentionsByRemoteExt(in: mutableAttrStr, message: message)
    if !didHighlight {
      let hasMention = !isRevoked && (
        (message?.mentionedAll == true) ||
        (message?.mentionedAccids.isEmpty == false)
      )
      if hasMention {
        highlightAtMentionsByRegex(in: mutableAttrStr, originalText: text)
      }
    }

    attributeStr = mutableAttrStr

    contentSize = NSAttributedString.getRealLabelSize(attributeStr, DefaultTextFont(16), CGSize(width: qChat_content_maxW - qChat_margin * 2, height: CGFloat.greatestFiniteMagnitude))

    if contentSize.height < qChat_min_h { // 小于一行高度，就保持一行
      contentSize.height = qChat_min_h
    }
  }

  // MARK: - @ 高亮辅助方法

  /// 通过 remoteExt 中的精确范围来高亮 @片段（完全对齐 ChatMessageHelper.loadAtInMessage 逻辑）
  ///
  /// 存储格式（由 QChatInputView.getAtRemoteExtension 生成）：
  ///   remoteExt["yxAitMsg"] = { accid: { "segments": [{"start": Int, "end": Int}], "text": String } }
  ///
  /// start/end 是"服务端索引"（emoji 按 tag 字符串长度计算），
  /// 渲染时需减去前缀 emoji 膨胀量还原成 UI 索引，与 loadAtInMessage 一致。
  ///
  /// - Returns: 是否找到并执行了高亮（true 表示无需再走正则兜底）
  @discardableResult
  private func highlightAtMentionsByRemoteExt(in attrStr: NSMutableAttributedString,
                                              message: NIMQChatMessage?) -> Bool {
    guard !isRevoked else { return false }

    // remoteExt 的值是 [AnyHashable: Any]，内层也可能是 [AnyHashable: Any]，
    // 必须用 AnyHashable key 来取，再逐层转型，避免 as? [String: Any] 直接失败。
    guard let remoteExt = message?.remoteExt else { return false }
    let atMsgKey: AnyHashable = qchat_yxAtMsg
    guard let atDicRaw = remoteExt[atMsgKey], !"\(atDicRaw)".isEmpty else { return false }

    // yxAitMsg 的值可能是：
    //   a) 本地刚发送的消息：Swift 原生字典 [AnyHashable: Any]
    //   b) 历史消息/SDK处理后：JSON 字符串，需要先反序列化
    let atDic: [AnyHashable: Any]
    if let nativeDict = atDicRaw as? [AnyHashable: Any] {
      atDic = nativeDict
    } else if let jsonStr = atDicRaw as? String,
              let jsonData = jsonStr.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [AnyHashable: Any] {
      atDic = parsed
    } else {
      print("[QChatAt-Debug] highlightAtMentionsByRemoteExt: yxAitMsg 值类型无法解析: \(type(of: atDicRaw))")
      return false
    }
    guard !atDic.isEmpty else { return false }

    let text = message?.text ?? ""
    let font = DefaultTextFont(16)
    var didHighlight = false
    var notFound = false

    // 第一轮：带表情索引补偿的精确高亮（对齐 loadAtInMessage 主逻辑）
    for (_, contentAny) in atDic {
      guard let contentDic = contentAny as? [AnyHashable: Any] else { continue }
      let segKey: AnyHashable = qchat_atSegmentsKey
      guard let segmentsRaw = contentDic[segKey] as? [Any] else { continue }

      for segAny in segmentsRaw {
        // segment 可能是 [String:Any] 或 [AnyHashable:Any]（JSON 解析后为后者）
        var startVal: Int?
        var endVal: Int?
        if let seg = segAny as? [String: Any] {
          startVal = (seg["start"] as? NSNumber)?.intValue ?? seg["start"] as? Int
          endVal   = (seg["end"]   as? NSNumber)?.intValue ?? seg["end"]   as? Int
        } else if let seg = segAny as? [AnyHashable: Any] {
          startVal = (seg["start"] as? NSNumber)?.intValue
          endVal   = (seg["end"]   as? NSNumber)?.intValue
        }
        guard let serverStart = startVal, let serverEnd = endVal else { continue }

        // ── 逆向补偿：服务端索引 → UI 索引（与 loadAtInMessage 完全一致）──
        // 1. 计算 [0, serverStart) 前缀文本中表情膨胀量
        var prefixReduceCount = 0
        if serverStart > 0, text.count > serverStart {
          let prefixText = String(text.prefix(serverStart))
          let prefixAttr = NEEmotionTool.getAttWithStr(str: prefixText, font: font)
          prefixReduceCount = qchatGetReduceIndexCount(prefixAttr)
        }
        let uiStart = serverStart - prefixReduceCount
        if uiStart < 0 { notFound = true; break }

        // 2. 计算 [serverStart, serverEnd) 片段内的表情膨胀量
        let segmentServerLen = serverEnd - serverStart
        if serverEnd + 1 > text.count { notFound = true; break }
        let segStartIdx = text.index(text.startIndex, offsetBy: serverStart)
        let segEndIdx   = text.index(text.startIndex, offsetBy: min(serverEnd + 1, text.count))
        let segText = String(text[segStartIdx ..< segEndIdx])
        let segAttr = NEEmotionTool.getAttWithStr(str: segText, font: font)
        let innerReduceCount = qchatGetReduceIndexCount(segAttr)
        let uiEnd = uiStart + segmentServerLen - innerReduceCount

        if uiEnd <= uiStart { notFound = true; break }

        // end 是半开区间右边界（含尾部空格），highlightLen = uiEnd - uiStart
        let highlightLen = uiEnd - uiStart
        if highlightLen > 0, uiStart + highlightLen <= attrStr.length {
          attrStr.addAttribute(.foregroundColor, value: UIColor.ne_normalTheme,
                               range: NSMakeRange(uiStart, highlightLen))
          didHighlight = true
        }
      }
      if notFound { break }
    }

    // 第二轮：若补偿逻辑遇到越界（notFound），退回直接用服务端索引（老版本兜底）
    if notFound {
      for (_, contentAny) in atDic {
        guard let contentDic = contentAny as? [AnyHashable: Any] else { continue }
        let segKey: AnyHashable = qchat_atSegmentsKey
        guard let segmentsRaw = contentDic[segKey] as? [Any] else { continue }
        for segAny in segmentsRaw {
          var startVal: Int?
          var endVal: Int?
          if let seg = segAny as? [String: Any] {
            startVal = (seg["start"] as? NSNumber)?.intValue ?? seg["start"] as? Int
            endVal   = (seg["end"]   as? NSNumber)?.intValue ?? seg["end"]   as? Int
          } else if let seg = segAny as? [AnyHashable: Any] {
            startVal = (seg["start"] as? NSNumber)?.intValue
            endVal   = (seg["end"]   as? NSNumber)?.intValue
          }
          guard let serverStart = startVal, let serverEnd = endVal else { continue }
          let highlightLen = serverEnd - serverStart + 1
          if serverStart >= 0, serverStart + highlightLen <= attrStr.length {
            attrStr.addAttribute(.foregroundColor, value: UIColor.ne_normalTheme,
                                 range: NSMakeRange(serverStart, highlightLen))
            didHighlight = true
          }
        }
      }
    }
    return didHighlight
  }

  /// 计算富文本中所有表情 attachment 带来的字符膨胀量（每个表情 = tag.count - 1 个额外字符）
  /// 与 ChatMessageHelper.getReduceIndexCount 逻辑完全一致
  private func qchatGetReduceIndexCount(_ attribute: NSAttributedString) -> Int {
    var count = 0
    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: NSAttributedString.EnumerationOptions(rawValue: 0)
    ) { dics, _, _ in
      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment,
         let tagCount = neAttachment.emotion?.tag?.count {
        count += tagCount - 1
      }
    }
    return count
  }

  /// RegEx 兜底高亮（用于无 remoteExt 的旧消息）
  private func highlightAtMentionsByRegex(in attrStr: NSMutableAttributedString, originalText: String) {
    guard let regex = try? NSRegularExpression(pattern: "@[^@\\s]+(\\s|$)", options: []) else {
      return
    }
    let nsText = originalText as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)
    let matches = regex.matches(in: originalText, options: [], range: fullRange)
    for match in matches {
      let highlightRange = match.range
      if highlightRange.location + highlightRange.length <= attrStr.length {
        attrStr.addAttribute(.foregroundColor, value: UIColor.ne_normalTheme, range: highlightRange)
      }
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
