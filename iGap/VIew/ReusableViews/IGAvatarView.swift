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


class IGAvatarView: UIView {
    
    private var initialLettersView: UIView?
    private var initialLettersLabel: UILabel?
    var avatarImageView: IGImageView?
    private var gradient: CAGradientLayer?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    
    private func configure() {
        self.layer.cornerRadius = self.frame.width / 2.0
        self.layer.masksToBounds = true
        
        let subViewsFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.subviews.forEach {
            $0.removeFromSuperview()
        }
        self.initialLettersView = UIView(frame: subViewsFrame)
        self.avatarImageView = IGImageView(frame: subViewsFrame)
        self.initialLettersLabel = UILabel(frame: subViewsFrame)
        
        self.avatarImageView?.contentMode = .scaleAspectFill
        
        self.addSubview(self.initialLettersView!)
        self.addSubview(self.initialLettersLabel!)
        self.addSubview(self.avatarImageView!)
        
        
        self.initialLettersLabel!.textColor = UIColor.white
        self.initialLettersLabel!.textAlignment = .center
        
        //let gradientStartColor = UIColor(red: 139.0/255.0, green: 139.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        //self.gradient = CAGradientLayer()
        //self.gradient!.frame = subViewsFrame
        //self.gradient!.colors = [gradientStartColor.cgColor, UIColor.clear.cgColor]
        //self.gradient!.startPoint = CGPoint(x: 1, y: 1)
        //self.gradient!.endPoint = CGPoint(x: 0, y: 0)
        //self.initialLettersView!.layer.insertSublayer(gradient!, at: 0)
        
        //let avatarBorderColor = UIColor(red: 140.0/255.0, green: 140.0/255.0, blue: 140.0/255.0, alpha: 1.0)
        //self.layer.borderWidth = 0.5
        //self.layer.borderColor = avatarBorderColor.cgColor
    }
    
    
    // MARK: - Public Setters
    func clean() {
        self.avatarImageView!.image = nil
        self.initialLettersLabel!.text = ""
    }
    
    func setUser(_ user: IGRegisteredUser) {
        if user.isInvalidated {
            return
        }
        self.avatarImageView!.image = nil
        self.initialLettersLabel!.text = user.initials
        let color = UIColor.hexStringToUIColor(hex: user.color)
        self.initialLettersView!.backgroundColor = color
        
        if let avatar = IGAvatar.getLastAvatar(ownerId: user.id), let avatarFile = avatar.file {
            self.avatarImageView!.setAvatar(avatar: avatarFile)
        } else if let avatar = user.avatar {
            self.avatarImageView!.setAvatar(avatar: avatar.file!)
        }
        
        if self.frame.size.width < 40 {
            self.initialLettersLabel!.font = UIFont.igFont(ofSize: 10.0)
        } else if self.frame.size.width < 60 {
            self.initialLettersLabel!.font = UIFont.igFont(ofSize: 14.0)
        } else {
            self.initialLettersLabel!.font = UIFont.igFont(ofSize: 17.0)
        }
    }
    
    func setRoom(_ room: IGRoom) {
        
        if room.isInvalidated {
            return
        }
        
        self.avatarImageView!.image = nil
        self.initialLettersLabel!.text = room.initilas

        let color = UIColor.hexStringToUIColor(hex: room.colorString)
        self.initialLettersView!.backgroundColor = color
        
        var ownerId: Int64 = room.id
        if room.type == .chat {
            ownerId = (room.chatRoom?.peer!.id)!
        }
        
        if let avatar = IGAvatar.getLastAvatar(ownerId: ownerId), let avatarFile = avatar.file {
            self.avatarImageView!.setAvatar(avatar: avatarFile)
            
        } else { /// HINT: old version dosen't have owernId so currently we have to check this state
            var file: IGFile?
            if room.type == .chat, let avatar = room.chatRoom?.peer?.avatar?.file {
                file = avatar
            } else if room.type == .group, let avatar = room.groupRoom?.avatar?.file {
                file = avatar
            } else if room.type == .channel, let avatar = room.channelRoom?.avatar?.file {
                file = avatar
            }
            
            if file != nil {
                self.avatarImageView!.setAvatar(avatar: file!)
            }
        }

        if self.frame.size.width < 40 {
            self.initialLettersLabel!.font = UIFont.igFont(ofSize: 10.0)
        } else if self.frame.size.width < 60 {
            self.initialLettersLabel!.font = UIFont.igFont(ofSize: 14.0)
        } else {
            self.initialLettersLabel!.font = UIFont.igFont(ofSize: 17.0)
        }
    }
    
    func setDefaultImage(_ image: UIImage) {
        self.avatarImageView!.image = UIImage(named: "AppIcon")
    }
}
