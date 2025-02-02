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
import Foundation

protocol IGDeleteSelectedCellDelegate: AnyObject{
    func contactViewWasSelected(cell: IGMemberChooseBottomCollectionCell)
}


class IGMemberChooseBottomCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var contactAvatarView: IGAvatarView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var contactNameLabel: UILabel!
    weak var cellDelegate: IGDeleteSelectedCellDelegate?
    var selectedRowIndexPathForTableView : IndexPath?
    var user : IGMemberAddOrUpdateState.User!{
        didSet{
            updateUI()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateUI() {
        contactNameLabel.text = user.registredUser.displayName
        contactAvatarView.setUser(user.registredUser)
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        cellDelegate?.contactViewWasSelected(cell: self)
    }

}
