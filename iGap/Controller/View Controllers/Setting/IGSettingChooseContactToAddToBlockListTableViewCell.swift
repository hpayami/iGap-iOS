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

class IGSettingChooseContactToAddToBlockListTableViewCell: UITableViewCell {

    @IBOutlet weak var userAvatarView: IGAvatarView!
    @IBOutlet weak var lastSeenStatusLable: UILabel!
    @IBOutlet weak var contactNameLable: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    func setUser(_ user: IGRegisteredUser) {
        contactNameLable.text = user.displayName
        userAvatarView.setUser(user)
    }

}
