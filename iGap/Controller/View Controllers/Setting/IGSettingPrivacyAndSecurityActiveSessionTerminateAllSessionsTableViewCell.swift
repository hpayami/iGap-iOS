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

class IGSettingPrivacyAndSecurityActiveSessionTerminateAllSessionsTableViewCell: UITableViewCell {
    @IBOutlet weak var terminateAllLable: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        terminateAllLable.text = IGStringsManager.TerminateAllSessions.rawValue.localized
        terminateAllLable.font = UIFont.igFont(ofSize: 15)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
