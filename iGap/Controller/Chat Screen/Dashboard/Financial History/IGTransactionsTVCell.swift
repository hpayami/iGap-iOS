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

class IGTransactionsTVCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var tokenLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        initTheme()
        
    }
    private func initTheme() {
        titleLbl.textColor = ThemeManager.currentTheme.LabelColor
        dateLbl.textColor = ThemeManager.currentTheme.LabelColor
        timeLbl.textColor = ThemeManager.currentTheme.LabelColor
        tokenLbl.textColor = ThemeManager.currentTheme.LabelColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
}
