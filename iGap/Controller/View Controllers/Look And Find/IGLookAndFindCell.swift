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
import IGProtoBuff

class IGLookAndFindCell: UITableViewCell {

    @IBOutlet weak var avatarView: IGAvatarView!
    @IBOutlet weak var txtIcon: UILabel!
    @IBOutlet weak var txtResultName: UILabel!
    @IBOutlet weak var txtResultUsername: UILabel!
    @IBOutlet weak var txtHeader: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        if txtIcon != nil {
            txtIcon.textColor = ThemeManager.currentTheme.LabelColor
        }
        if txtResultName != nil {
            txtResultName.textColor = ThemeManager.currentTheme.LabelColor
        }
        if txtResultUsername != nil {
            txtResultUsername.textColor = ThemeManager.currentTheme.LabelColor
        }
        if txtHeader != nil {
            txtHeader.textColor = ThemeManager.currentTheme.LabelColor
        }


    }
    
    func setSearchResult(result: IGLookAndFindStruct){
        if result.type == .channel || result.type == .group {
            if result.room != nil {
                setRoom(room: result.room)
            }
        } else if result.type == .user { // users & bots
            if result.user != nil {
                setUser(user: result.user)
            }
        } else if result.type == .message || result.type == .hashtag {
            if result.message != nil {
                setMessage(message: result.message)
            }
        }
    }
    
    func setHeader(type: IGSearchType){
        txtHeader.font = UIFont.igFont(ofSize: 15)
        if type == .channel {
            txtHeader.text = IGStringsManager.Channels.rawValue.localized
        } else if type == .group {
            txtHeader.text = IGStringsManager.Groups.rawValue.localized
        } else if type == .user {
            txtHeader.text = IGStringsManager.Contacts.rawValue.localized
        } else if type == .bot {
            txtHeader.text = IGStringsManager.Bot.rawValue.localized
        } else if type == .message {
            txtHeader.text = IGStringsManager.Messages.rawValue.localized
        } else if type == .hashtag {
            txtHeader.text = IGStringsManager.Hashtags.rawValue.localized
        }
        txtHeader.textColor = ThemeManager.currentTheme.LabelColor

    }
    
    private func setRoom(room: IGRoom, message: String? = nil) {
        txtResultName.text = room.title
        
        if message != nil {
            txtResultUsername.text = message
            if room.type == .chat {
                txtIcon.text = ""
            } else if room.type == .group {
                txtIcon.text = ""
            } else if room.type == .channel {
                txtIcon.text = ""
            }
        } else {
            if room.type == IGRoom.IGType.chat {
                txtResultUsername.text = room.chatRoom?.peer?.username
                txtIcon.text = ""
            } else if room.type == IGRoom.IGType.group {
                txtResultUsername.text = room.groupRoom?.publicExtra?.username
                txtIcon.text = ""
            } else if room.type == IGRoom.IGType.channel {
                txtResultUsername.text = room.channelRoom?.publicExtra?.username
                txtIcon.text = ""
            }
        }
        
        avatarView.setRoom(room)
        txtIcon.textColor = ThemeManager.currentTheme.LabelColor
        txtResultName.textColor = ThemeManager.currentTheme.LabelColor
        txtResultUsername.textColor = ThemeManager.currentTheme.LabelColor

    }
    
    private func setUser(user: IGRegisteredUser, message: String? = nil) {
        txtResultName.text = user.displayName
        if message != nil {
            txtResultUsername.text = message
        } else {
            txtResultUsername.text = user.username
        }
        txtIcon.text = ""
        
        avatarView.setUser(user)
        txtIcon.textColor = ThemeManager.currentTheme.LabelColor
        txtResultName.textColor = ThemeManager.currentTheme.LabelColor
        txtResultUsername.textColor = ThemeManager.currentTheme.LabelColor

    }
    
    private func setMessage(message: IGRoomMessage){
        
        var finalMessage = message
        if let forward = message.forwardedFrom {
            finalMessage = forward
        }
        
        if let user = finalMessage.authorUser?.user {
            setUser(user: user, message: finalMessage.message)
        } else if let room = message.authorRoom {

            if room.roomInfo != nil  {
                setRoom(room: room.roomInfo, message: finalMessage.message)

            } else {
                IGClientGetRoomRequest.sendRequestAvoidDuplicate(roomId: room.roomId) {[weak self] (_) in
                    guard let sSelf = self else {
                        return
                    }
                    sSelf.setRoom(room: room.roomInfo, message: finalMessage.message)

                }
            }
        }
        //setRoom(room: IGRoom.getRoomInfo(roomId: message.roomId), message: message.message)
    }
}
