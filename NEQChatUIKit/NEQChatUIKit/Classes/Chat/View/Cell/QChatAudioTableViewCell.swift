
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

protocol QChatAudioCell {
  var isPlaying: Bool { get set }
  func startAnimation()
  func stopAnimation()
}

class QChatAudioTableViewCell: QChatBaseTableViewCell, QChatAudioCell {
  var isPlaying: Bool = false

  // 白色背景
  let backView = QChatBubbleButton()

  var audioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "play_3"))
  var timeLabel = UILabel()

  var leftAudioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "left_play_3"))
  var leftTimeLabel = UILabel()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  func commonUI() {
    audioImageView.contentMode = .center
    audioImageView.translatesAutoresizingMaskIntoConstraints = false
    contentBtn.addSubview(audioImageView)
    NSLayoutConstraint.activate([
      audioImageView.rightAnchor.constraint(equalTo: contentBtn.rightAnchor, constant: -16),
      audioImageView.topAnchor.constraint(equalTo: contentBtn.topAnchor, constant: 6),
      audioImageView.widthAnchor.constraint(equalToConstant: 28),
      audioImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    timeLabel.font = UIFont.systemFont(ofSize: 14)
    timeLabel.textColor = UIColor.ne_darkText
    timeLabel.textAlignment = .right
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    contentBtn.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(equalTo: audioImageView.leftAnchor, constant: -12),
      timeLabel.centerYAnchor.constraint(equalTo: audioImageView.centerYAnchor),
      timeLabel.heightAnchor.constraint(equalToConstant: 28),
    ])

    audioImageView.animationDuration = 1
    if let image1 = UIImage.ne_imageNamed(name: "play_1"),
       let image2 = UIImage.ne_imageNamed(name: "play_2"),
       let image3 = UIImage.ne_imageNamed(name: "play_3") {
      audioImageView.animationImages = [image1, image2, image3]
    }

    leftAudioImageView.contentMode = .center
    leftAudioImageView.translatesAutoresizingMaskIntoConstraints = false
    contentBtn.addSubview(leftAudioImageView)
    NSLayoutConstraint.activate([
      leftAudioImageView.leftAnchor.constraint(equalTo: contentBtn.leftAnchor, constant: 16),
      leftAudioImageView.topAnchor.constraint(equalTo: contentBtn.topAnchor, constant: 6),
      leftAudioImageView.widthAnchor.constraint(equalToConstant: 28),
      leftAudioImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    leftTimeLabel.font = UIFont.systemFont(ofSize: 14)
    leftTimeLabel.textColor = UIColor.ne_darkText
    leftTimeLabel.textAlignment = .left
    leftTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    contentBtn.addSubview(leftTimeLabel)
    NSLayoutConstraint.activate([
      leftTimeLabel.leftAnchor.constraint(equalTo: leftAudioImageView.rightAnchor, constant: 12),
      leftTimeLabel.centerYAnchor.constraint(equalTo: leftAudioImageView.centerYAnchor),
      leftTimeLabel.rightAnchor.constraint(equalTo: contentBtn.rightAnchor, constant: -12),
      leftTimeLabel.heightAnchor.constraint(equalToConstant: 28),
    ])
    leftAudioImageView.animationDuration = 1
    if let leftImage1 = UIImage.ne_imageNamed(name: "left_play_1"),
       let leftImage2 = UIImage.ne_imageNamed(name: "left_play_2"),
       let leftImage3 = UIImage.ne_imageNamed(name: "left_play_3") {
      leftAudioImageView.animationImages = [leftImage1, leftImage2, leftImage3]
    }

    backView.isUserInteractionEnabled = false
    backView.backgroundColor = .clear
    backView.layer.cornerRadius = 4
  }

  override var messageFrame: QChatMessageFrame? {
    didSet {
      if isPlaying {
        stopAnimation()
      }
      if let m = messageFrame {
        timeLabel.text = "\(m.duration)" + "s"
        leftTimeLabel.text = "\(m.duration)" + "s"
        m.isPlaying ? startAnimation() : stopAnimation()
      }

      backView.removeFromSuperview()
      if let isSend = messageFrame?.message?.isOutgoingMsg {
        if isSend == true {
          timeLabel.isHidden = false
          audioImageView.isHidden = false
          leftTimeLabel.isHidden = true
          leftAudioImageView.isHidden = true

          if messageFrame?.quickComments?.count ?? 0 > 0 {
            if let contentW = messageFrame?.contentSize.width {
              backView.setBubbleImage(image: UIImage.ne_imageNamed(name: "audio_back_right")!)
              backView.frame = CGRect(x: contentBtn.width - contentW - qChat_margin, y: 6, width: contentW, height: 28)
              contentBtn.insertSubview(backView, belowSubview: audioImageView)
            }
          }
        } else {
          timeLabel.isHidden = true
          audioImageView.isHidden = true
          leftTimeLabel.isHidden = false
          leftAudioImageView.isHidden = false

          if messageFrame?.quickComments?.count ?? 0 > 0 {
            if let contentW = messageFrame?.contentSize.width {
              backView.setBubbleImage(image: UIImage.ne_imageNamed(name: "audio_back_left")!)
              backView.frame = CGRect(x: qChat_margin, y: 6, width: contentW, height: 28)
              contentBtn.insertSubview(backView, belowSubview: leftAudioImageView)
            }
          }
        }
      }
    }
  }

  func startAnimation() {
    didStartAnimation()
    if let m = messageFrame {
      m.isPlaying = true
      isPlaying = true
    }
  }

  func stopAnimation() {
    didStopAnimation()
    if let m = messageFrame {
      m.isPlaying = false
      isPlaying = false
    }
  }

  private func didStopAnimation() {
    if audioImageView.isAnimating {
      audioImageView.stopAnimating()
    }
    if leftAudioImageView.isAnimating {
      leftAudioImageView.stopAnimating()
    }
  }

  private func didStartAnimation() {
    if !audioImageView.isAnimating {
      audioImageView.startAnimating()
    }
    if !leftAudioImageView.isAnimating {
      leftAudioImageView.startAnimating()
    }
  }

//    override func setModel(_ model: MessageContentModel) {
//      super.setModel(model)
//      if let m = model as? MessageAudioModel {
//        timeLabel.text = "\(m.duration)" + "s"
//        m.isPlaying ? startAnimation() : stopAnimation()
//      }
//    }
}
