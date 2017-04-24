/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the RooyeKhat Media Company - www.RooyeKhat.co
 * All rights reserved.
 */

import UIKit

class IGSettingPrivacyAndSecurityActiveSessionMoreDetailsTableViewCell: UITableViewCell {
    @IBOutlet weak var moreDetailsLable: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        moreDetailsLable.text = "More Details"
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    func setSession(_ session : IGSession) {
        moreDetailsLable.text = "More Details"
        self.accessoryType = .disclosureIndicator
    }
}
