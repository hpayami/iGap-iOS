/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import AsyncDisplayKit
import SnapKit
import SwiftEventBus

class IGVoiceNode: AbstractNode {
    private var txtCurrentTimeNode = ASTextNode()
    private var txtVoiceTimeNode = ASTextNode()
    
    override init(message: IGRoomMessage, isIncomming: Bool, isTextMessageNode: Bool = true,finalRoomType : IGRoom.IGType,finalRoom : IGRoom) {
        super.init(message: message, isIncomming: isIncomming, isTextMessageNode: isTextMessageNode,finalRoomType : finalRoomType, finalRoom: finalRoom)
        setupView()
    }
    
    override func didLoad() {
        super.didLoad()
        self.setVoice()
        self.voiceGustureRecognizers()
        self.checkPlayerState()
    }
    
    override func setupView() {
        super.setupView()
        
        sliderNode.style.preferredSize = CGSize(width: 150, height: 50)
        (sliderNode.view as! UISlider).maximumTrackTintColor = .black
        (sliderNode.view as! UISlider).minimumTrackTintColor = .red
        (sliderNode.view as! UISlider).tintColor = .green

        btnStateNode.layer.cornerRadius = 25
        
        //make current time text
        IGGlobal.makeAsyncText(for: self.txtCurrentTimeNode, with: "00:00".inLocalizedLanguage(), textColor: .lightGray, size: 12, numberOfLines: 1, font: .igapFont,alignment: .left)
        //        msgTextNode.isUserInteractionEnabled = true
        addSubnode(sliderNode)
       let slider = sliderNode.view as? UISlider
        print(slider!.maximumValue)
        
        addSubnode(txtVoiceTimeNode)
        addSubnode(txtCurrentTimeNode)
        addSubnode(btnStateNode)
        addSubnode(indicatorViewAbs)
        checkButtonState(btn: btnStateNode)
    }
    
    
    func checkButtonState(btn : ASButtonNode) {
        if IGGlobal.isFileExist(path: message.attachment!.localPath, fileSize: message.attachment!.size) {
            indicatorViewAbs.isHidden = true
            indicatorViewAbs.style.preferredSize = CGSize.zero
            btnStateNode.style.preferredSize = CGSize(width: 50, height: 50)
            btnStateNode.setTitle("🎗", with: UIFont.iGapFonticon(ofSize: 35), with: .black, for: .normal)
            
        } else {
            indicatorViewAbs.isHidden = false
            indicatorViewAbs.style.preferredSize = CGSize(width: 50, height: 50)
            btnStateNode.style.preferredSize = CGSize.zero
            btnStateNode.style.preferredSize = CGSize(width: 50, height: 50)
            btnStateNode.setTitle("🎗", with: UIFont.iGapFonticon(ofSize: 35), with: .black, for: .normal)

        }
        
        
    }
    

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let sliderBox = ASStackLayoutSpec.vertical()
        sliderBox.justifyContent = .start
        sliderBox.alignContent = .stretch
        sliderBox.children = [sliderNode, txtCurrentTimeNode]
        sliderBox.spacing = 0
        
        let overlayBox = ASOverlayLayoutSpec(child: btnStateNode, overlay: indicatorViewAbs)
        
        let attachmentBox = ASStackLayoutSpec.horizontal()
        attachmentBox.spacing = 8
        attachmentBox.children = [overlayBox, sliderBox]

        let insetBox = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8),
            child: attachmentBox
        )
        
        return insetBox
        
    }
    
    private func setVoice(){
        
        let attachment: IGFile! = message.attachment
        
        if isIncomming {
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb"), for: .normal)
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb"), for: .focused)
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb"), for: .selected)
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb"), for: .highlighted)
            (sliderNode.view as! UISlider).minimumTrackTintColor = ThemeManager.currentTheme.MessageTextReceiverColor
            (sliderNode.view as! UISlider).maximumTrackTintColor = UIColor.black
            IGGlobal.makeAsyncButton(for: btnStateNode, with: "", textColor: .black, size: 35, font: .fontIcon, alignment: .center)
        } else {
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb_Outgoing"), for: .normal)
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb_Outgoing"), for: .focused)
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb_Outgoing"), for: .selected)
            (sliderNode.view as! UISlider).setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb_Outgoing"), for: .highlighted)
            (sliderNode.view as! UISlider).maximumTrackTintColor = UIColor.black
            (sliderNode.view as! UISlider).minimumTrackTintColor = UIColor(red: 22.0/255.0, green: 91.0/255.0, blue: 88.0/255.0, alpha: 1.0)
            IGGlobal.makeAsyncButton(for: btnStateNode, with: "", textColor: .black, size: 35, font: .fontIcon, alignment: .center)
        }
        
        
        (sliderNode.view as! UISlider).setValue(0.0, animated: false)
        let timeM = Int(attachment.duration / 60)
        let timeS = Int(attachment.duration.truncatingRemainder(dividingBy: 60.0))
        IGGlobal.makeAsyncText(for: txtVoiceTimeNode, with: "0:00 / \(timeM):\(timeS)".inLocalizedLanguage(), textColor: .black, size: 13, font: .igapFont, alignment: .center)
    }
    
    
    /****************************************************************************/
    /******************************* Voice Player *******************************/
    
    /** check current voice state and if is playing update values to current state */
    private func checkPlayerState(){
        IGNodePlayer.shared.startPlayer(btnPlayPause: self.btnStateNode, slider: (self.sliderNode.view as! UISlider), timer: self.txtCurrentTimeNode, roomMessage: self.message, justUpdate: true)
    }
    
    private func voiceGustureRecognizers() {
        self.btnStateNode.addTarget(self, action: #selector(self.didTapOnPlay(_:)), forControlEvents: .touchUpInside)
    }
    
    @objc func didTapOnPlay(_ gestureRecognizer: UITapGestureRecognizer) {
        IGGlobal.isVoice = true // determine the file is voice and not music

        IGNodePlayer.shared.startPlayer(btnPlayPause: self.btnStateNode, slider: (self.sliderNode.view as! UISlider), timer: self.txtCurrentTimeNode, roomMessage: self.message)
    }
    
    
}


