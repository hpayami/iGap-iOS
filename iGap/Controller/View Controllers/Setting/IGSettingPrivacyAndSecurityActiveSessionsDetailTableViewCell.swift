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

class IGSettingPrivacyAndSecurityActiveSessionsDetailTableViewCell: UITableViewCell {
    let greenColor = UIColor.organizationalColor()
    
    @IBOutlet weak var activeSessionImageView: UIImageView!
    @IBOutlet weak var activeSessionTitle: UILabel!
    @IBOutlet weak var activeSessionLastseenLable: UILabel!
    @IBOutlet weak var activesessionCountryLable: UILabel!
    var items : [IGSession]?{
        didSet{
            
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        activeSessionLastseenLable.textColor = greenColor
    }

    func setSession(_ session: IGSession) {
        switch session.platform! {
        case .android :
            activeSessionTitle.text = IGStringsManager.Android.rawValue.localized
            activeSessionImageView.image = UIImage(named:"IG_Settings_Active_Sessions_Device_Android")
        case .iOS :
            activeSessionTitle.text = IGStringsManager.IOS.rawValue.localized
            activeSessionImageView.image = UIImage(named:"IG_Settings_Active_Sessions_Device_iPhone")
        case .macOS :
            activeSessionTitle.text = IGStringsManager.MacOs.rawValue.localized
            activeSessionImageView.image = UIImage(named:"IG_Settings_Active_Sessions_Device_Mac")
        case .windows :
            activeSessionTitle.text = IGStringsManager.Widnows.rawValue.localized
            activeSessionImageView.image = UIImage(named:"IG_Settings_Active_Sessions_Device_Windows")
        case .linux :
            activeSessionTitle.text = IGStringsManager.Linux.rawValue.localized
            activeSessionImageView.image = UIImage(named:"IG_Settings_Active_Sessions_Device_Linux")
        case .blackberry :
            activeSessionTitle.text = "blackberry"
        default:
            break
        }
        
        let lastActiveDateString = Date(timeIntervalSince1970: TimeInterval(session.activeTime)).completeHumanReadableTime()
        activeSessionLastseenLable.text = IGStringsManager.LastActiveAt.rawValue.localized + lastActiveDateString.inLocalizedLanguage()
        activesessionCountryLable.text = session.country
        
    }
}
