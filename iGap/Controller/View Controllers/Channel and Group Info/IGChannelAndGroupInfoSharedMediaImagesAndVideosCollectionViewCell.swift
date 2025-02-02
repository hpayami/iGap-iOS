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
import RxSwift
import RealmSwift
import Gifu

class IGChannelAndGroupInfoSharedMediaImagesAndVideosCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var sharedMediaImageView: UIImageView!
    @IBOutlet weak var videoSizeLabel: UILabel!
    @IBOutlet weak var mediaDownloadIndicator: IGProgress!
    let disposeBag = DisposeBag()
    
    var attachment: IGFile?
    var txtVideoPlay: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    override func awakeFromNib() {
        
        self.sharedMediaImageView.layer.cornerRadius = 15
        self.videoSizeLabel.roundCorners(corners: [.layerMaxXMaxYCorner,.layerMinXMaxYCorner], radius: 15)
        self.sharedMediaImageView.clipsToBounds = true
        self.videoSizeLabel.layer.masksToBounds = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        sharedMediaImageView.image = nil
        videoSizeLabel.text = nil
        self.mediaDownloadIndicator.prepareForReuse()
        self.mediaDownloadIndicator.isHidden = true
        self.sharedMediaImageView.isHidden = true
    }
    
    func setMediaIndicator(message: IGRoomMessage) {
        if let msgAttachment = message.attachment {
            if let messageAttachmentVariableInCache = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: msgAttachment.cacheID!) {
                self.attachment = messageAttachmentVariableInCache.value
            } else {
                self.attachment = msgAttachment.detach()
                //let attachmentRef = ThreadSafeReference(to: msgAttachment)
                IGAttachmentManager.sharedManager.add(attachment: attachment!)
                self.attachment = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: msgAttachment.cacheID!)?.value
            }
            
            
            if let variableInCache = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: msgAttachment.cacheID!) {
                attachment = variableInCache.value
                variableInCache.asObservable().subscribe({ (event) in
                    DispatchQueue.main.async {
                        self.updateAttachmentDownloadUploadIndicatorView()
                    }
                }).disposed(by: disposeBag)
            }
            
            //MARK: ▶︎ Rx End
            switch (message.type) {
            case .image, .imageAndText, .video, .videoAndText:
                self.sharedMediaImageView.isHidden = false
                self.mediaDownloadIndicator.isHidden = false
                let progress = Progress(totalUnitCount: 100)
                progress.completedUnitCount = 0
                
                self.sharedMediaImageView.setThumbnail(for: msgAttachment)
                
                if msgAttachment.status != .ready {
                    self.mediaDownloadIndicator.delegate = self
                }
            default:
                break
            }
        }
    }
    
    func updateAttachmentDownloadUploadIndicatorView() {
        if let attachment = self.attachment {
            removeVideoPlayView()
            if IGGlobal.isFileExist(path: attachment.localPath, fileSize: attachment.size) {
                self.mediaDownloadIndicator.setState(.ready)
                if attachment.type == .image {
                    self.sharedMediaImageView.setThumbnail(for: attachment)
                } else if attachment.type == .video {
                    self.sharedMediaImageView.setThumbnail(for: attachment)
                    makeVideoPlayView()
                }
                
                return
            }
            
            switch attachment.type {
            case .video, .image:
                self.mediaDownloadIndicator.setFileType(.download)
                self.mediaDownloadIndicator.setState(attachment.status)
                if attachment.status == .downloading ||  attachment.status == .uploading {
                    self.mediaDownloadIndicator.setPercentage(attachment.downloadUploadPercent)
                }
            default:
                break
            }
        }
    }
    
    private func makeVideoPlayView(){
        if txtVideoPlay == nil {
            txtVideoPlay = UILabel()
            txtVideoPlay.font = UIFont.iGapFonticon(ofSize: 40)
            txtVideoPlay.textAlignment = NSTextAlignment.center
            txtVideoPlay.text = ""
            txtVideoPlay.textColor = UIColor.white
            txtVideoPlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            txtVideoPlay.layer.masksToBounds = true
            txtVideoPlay.layer.cornerRadius = 27.5
            self.addSubview(txtVideoPlay)
        }
        
        txtVideoPlay?.snp.makeConstraints { (make) in
            make.width.equalTo(55)
            make.height.equalTo(55)
            make.centerX.equalTo(sharedMediaImageView.snp.centerX)
            make.centerY.equalTo(sharedMediaImageView.snp.centerY)
        }
    }
    
    private func removeVideoPlayView(){
        txtVideoPlay?.removeFromSuperview()
        txtVideoPlay = nil
    }
}
extension IGChannelAndGroupInfoSharedMediaImagesAndVideosCollectionViewCell: IGProgressDelegate {
    func downloadUploadIndicatorDidTap(_ indicator: IGProgress) {
        if let attachment = self.attachment {
            IGDownloadManager.sharedManager.download(file: attachment, previewType: .originalFile, completion: { (attachment) -> Void in }, failure: {})
        }
    }
}
