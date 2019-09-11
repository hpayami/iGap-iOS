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
import MGSwipeTableCell

class IGSettingContactTableViewCell: MGSwipeTableCell {
    @IBOutlet weak var blockedLabel: UILabel!
    @IBOutlet weak var userAvatarView: IGAvatarView!
    @IBOutlet weak var contactNameLable: UILabel!
    @IBOutlet weak var lastSeenStatusLabel: UILabel!
    @IBOutlet weak var btnCall: UIButton!
    
    var registeredUser: IGRegisteredUser!

    override func awakeFromNib() {
        super.awakeFromNib()
        blockedLabel.isHidden = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func btnCall(_ sender: UIButton) {
        
        if IGCall.callPageIsEnable {
            return
        }
        
        if let delegate = IGSettingContactsTableViewController.callDelegate {
            delegate.call(user: registeredUser,mode:"voiceCall")
        }
        
    }
    
    func setUser(_ user: IGRegisteredUser) {
        btnCall.removeUnderline()
        self.registeredUser = user
        
        contactNameLable.text = user.displayName
        contactNameLable.textAlignment = contactNameLable.localizedNewDirection
        userAvatarView.setUser(user)
        if user.isBlocked {
            blockedLabel.isHidden = false
            
        }else if user.isBlocked == false {
            blockedLabel.isHidden = true
        }
        switch user.lastSeenStatus {
        case .exactly:
            if let lastSeenTime = user.lastSeen {
                lastSeenStatusLabel.text = "\(lastSeenTime.humanReadableForLastSeen())"
            }
            break
        case .lastMonth:
            lastSeenStatusLabel.text = "LAST_MONTH".localizedNew
            break
        case .lastWeek:
            lastSeenStatusLabel.text = "LAST_WEAK".localizedNew
            break
        case .longTimeAgo:
            lastSeenStatusLabel.text = "A_LONG_TIME_AGO".localizedNew
            break
        case .online:
            lastSeenStatusLabel.text = "ONLINE".localizedNew
            break
        case .recently:
            lastSeenStatusLabel.text = "LAST_SEEN_RECENTLY".localizedNew
            break
        case .support:
            lastSeenStatusLabel.text = "IGAP_SUPPORT".localizedNew
            break
        case .serviceNotification:
            lastSeenStatusLabel.text = "SERVICE_NOTIFI".localizedNew
            
            break
            

        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            self.setUser(user)
//        }

    }

}
