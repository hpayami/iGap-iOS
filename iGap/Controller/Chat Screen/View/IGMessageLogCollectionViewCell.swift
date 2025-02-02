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
import SnapKit

class IGMessageLogCollectionViewCell: IGMessageGeneralCollectionViewCell {

    @IBOutlet weak var logLabel: UILabel!
    @IBOutlet weak var logLableWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var logBackgroundView: UIView!
    @IBOutlet weak var logBackgroundWidthConstraint: NSLayoutConstraint!
    
    //MARK: - Class Methods
    class func nib() -> UINib {
        return UINib(nibName: "IGMessageLogCollectionViewCell", bundle: Bundle(for: self))
    }
    
    class func cellReuseIdentifier() -> String {
        return NSStringFromClass(self)
    }
    
    //MARK: - Instance Method
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.cellMessage = nil
        self.delegate = nil
        self.contentView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
    }
    
    func setLogMessage(_ message: IGRoomMessage) {
        self.cellMessage = message
        self.logLabel.textColor = UIColor.white
        self.logLabel.lineBreakMode = .byTruncatingMiddle
        if message.log?.type == .pinnedMessage {
            self.logLabel.text = IGRoomMessage.detectPinMessage(message: message)
        } else {
            if SMLangUtil.loadLanguage() == "fa" || SMLangUtil.loadLanguage() == "ar" {
                self.logLabel.text = IGRoomMessageLog.textForLogMessage(message)
//                self.logLabel.textAlignment = .right

            } else {
                self.logLabel.text = IGRoomMessageLog.textForLogMessage(message)
//                self.logLabel.textAlignment = .left


            }
        }
        self.logBackgroundView.layer.cornerRadius = 12.0
        self.logBackgroundView.backgroundColor = UIColor.logBackground()
        addShadow()
        manageWidth(IGRoomMessageLog.textForLogMessage(message))
        let currentTheme = UserDefaults.standard.string(forKey: "CurrentTheme") ?? "IGAPClassic"
        let currentColorSetLight = UserDefaults.standard.string(forKey: "CurrentColorSetLight") ?? "IGAPBlue"

        if currentTheme == "IGAPDay" {
            if currentColorSetLight == "IGAPBlack" {
                self.logLabel.textColor = .white
            } else {
                self.logLabel.textColor = .white
            }
        } else {
            self.logLabel.textColor = .white
        }
        self.logBackgroundView.backgroundColor = ThemeManager.currentTheme.SliderTintColor
    }
    
    func setUnreadMessage(_ message: IGRoomMessage){
        self.logLabel.textColor = UIColor.white
        self.logLabel.text = message.message
        self.logBackgroundView.layer.cornerRadius = 12.0
        self.logBackgroundView.backgroundColor = UIColor.unreadBackground()
        addShadow()
        logLableWidthConstraint.constant = (message.message!.width(withConstrainedHeight: 25, font: UIFont.igFont(ofSize: 14, weight: .medium)))
        logBackgroundWidthConstraint.constant = IGGlobal.fetchUIScreen().width - 20
    }
    
    func setUnknownMessage(){
        self.logLabel.textColor = UIColor.white
        self.logLabel.text = IGStringsManager.UnknownMessage.rawValue.localized
        self.logBackgroundView.layer.cornerRadius = 12.0
        self.logBackgroundView.backgroundColor = UIColor.logBackground()
        addShadow()
        manageWidth(IGStringsManager.UnknownMessage.rawValue.localized)
    }
    
    
    func setText(_ text: String) {
        self.logLabel.textColor = UIColor.white
        self.logLabel.text = text
        self.logBackgroundView.layer.cornerRadius = 12.0
        self.logBackgroundView.backgroundColor = UIColor.logBackground()
        addShadow()
        manageWidth(text)
    }
    
    func setTime(_ time: String) {
        self.logLabel.textColor = UIColor.white
        self.logLabel.text = time
        self.logBackgroundView.layer.cornerRadius = 12.0
        self.logBackgroundView.backgroundColor = UIColor.logBackground()
        addShadow()
        manageWidth(time)
    }
    
    private func manageWidth(_ message: String?){
        let maxSize: CGFloat = IGGlobal.fetchUIScreen().width - 40
        var size: CGFloat!
        
        if message != nil {
            size = (message?.width(withConstrainedHeight: 25, font: UIFont.igFont(ofSize: 15)))!
        }
        
        if size > maxSize {
            size = maxSize
        }
        logLableWidthConstraint.constant = size
        logBackgroundWidthConstraint.constant = size + 20
    }
    
    private func addShadow(){
        self.logBackgroundView.layer.shadowColor = UIColor.black.cgColor
        self.logBackgroundView.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        self.logBackgroundView.layer.shadowRadius = 2.5
        self.logBackgroundView.layer.shadowOpacity = 0.3
        self.logBackgroundView.layer.masksToBounds = false
    }
}
