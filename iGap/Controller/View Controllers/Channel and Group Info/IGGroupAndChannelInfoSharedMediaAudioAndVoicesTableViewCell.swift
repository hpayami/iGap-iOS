/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import UIKit
import AVFoundation
import MediaPlayer
import RxSwift

class IGGroupAndChannelInfoSharedMediaAudioAndVoicesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mediaCoverImageView: UIImageView!
    @IBOutlet weak var mediaSizeLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var playingSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var indicatorView: IGProgress!
    private var player = IGMusicPlayer.sharedPlayer
    private var playerWatcherIndex = 0
    var flag: Bool = false
    var attachment: IGFile?
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()   
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        self.indicatorView.prepareForReuse()
        self.indicatorView.isHidden = true
        self.mediaCoverImageView.isHidden = true
    }
    
    func setMediaPlayer(attachment: IGFile , message: IGRoomMessage) {
        
        if let messageAttachmentVariableInCache = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: attachment.cacheID!) {
            self.attachment = messageAttachmentVariableInCache.value
        } else {
            self.attachment = attachment.detach()
            IGAttachmentManager.sharedManager.add(attachment: self.attachment!)
            self.attachment = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: attachment.cacheID!)?.value
        }
        
        self.mediaSizeLabel.text = IGAttachmentManager.sharedManager.convertFileSize(sizeInByte: attachment.size).inLocalizedLanguage()
        
        if let creationtime = message.creationTime {
            creationDateLabel.text = "\(creationtime.completeHumanReadableTime())"
        }
        
        if attachment.type == .voice {
            songNameLabel.text = attachment.name
        }
        if attachment.type == .audio {
            songNameLabel.text = attachment.name
        }
        
        let timeInt = Int(attachment.duration)
        let remainingSeconds = timeInt%60
        let remainingMiuntes = timeInt/60
        durationTimeLabel.text = "\(remainingMiuntes):\(remainingSeconds)".inLocalizedLanguage()
        
        if let variableInCache = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: attachment.cacheID!) {
            self.attachment = variableInCache.value
            variableInCache.asObservable().subscribe({ (event) in
                DispatchQueue.main.async {
                    self.updateAttachmentDownloadUploadIndicatorView()
                }
            }).disposed(by: disposeBag)
        }
        
        switch (message.type) {
        case .audio, .audioAndText, .voice:
            
            self.indicatorView.isHidden = false
            self.mediaCoverImageView.isHidden = false
            
            Progress(totalUnitCount: 100).completedUnitCount = 0
            setImage(file: attachment) //self.mediaCoverImageView.setThumbnail(for: attachment)
            
            if attachment.status != .ready {
                self.indicatorView.delegate = self
            }
            
        default:
            break
        }
    }
    
    func updateAttachmentDownloadUploadIndicatorView() {
        if let attachment = self.attachment {
            if IGGlobal.isFileExist(path: attachment.localPath, fileSize: attachment.size) {
                self.indicatorView.setState(.ready)
                if attachment.type == .audio {
                    setImage(file: attachment)
                }
                return
            }
            
            switch attachment.type {
            case .audio, .voice:
                self.indicatorView.setFileType(.download)
                self.indicatorView.setState(attachment.status)
                if attachment.status == .downloading || attachment.status == .uploading {
                    self.indicatorView.setPercentage(attachment.downloadUploadPercent)
                }
            default:
                break
            }
        }
    }
    
    func setImage(file: IGFile){
        if file.type == .voice {
//            mediaCoverImageView.image = UIImage(named: "IG_Music_Player_Mic")
        } else if file.type == .audio {
            mediaCoverImageView.setThumbnail(for: file)
        }
    }
}

extension IGGroupAndChannelInfoSharedMediaAudioAndVoicesTableViewCell: IGProgressDelegate {
    
    func downloadUploadIndicatorDidTap(_ indicator: IGProgress) {
        if let attachment = self.attachment {
            IGDownloadManager.sharedManager.download(file: attachment, previewType: .originalFile, completion: { (attachment) -> Void in }, failure: {})
        }
    }
}
