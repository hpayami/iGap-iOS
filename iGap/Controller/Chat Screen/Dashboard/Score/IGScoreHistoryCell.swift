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

class IGScoreHistoryCell: UICollectionViewCell {
    
    @IBOutlet weak var txtScoreIcon: UILabel!
    @IBOutlet weak var txtScoreNumber: UILabel!
    @IBOutlet weak var txtTime: UILabel!
    @IBOutlet weak var txtTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        txtScoreIcon.font = UIFont.iGapFonticon(ofSize: 20)
        txtScoreNumber.textAlignment = txtScoreNumber.localizedDirection
        txtTitle.textAlignment = txtTitle.localizedDirection
    }
    
    public func initView(activity: IGPIVandActivity){
        txtScoreNumber.text = String(describing: abs(activity.igpScore)).inLocalizedLanguage()
        txtTime.text = Date(timeIntervalSince1970: TimeInterval(activity.igpTime)).completeHumanReadableTime().inLocalizedLanguage()
        txtTitle.text = activity.igpTitle
        
        if activity.igpScore == 0 { // score without any action
            txtScoreIcon.text = ""
            txtScoreIcon.textColor = UIColor.iGapGray()
        } else if activity.igpScore > 0 { // score up
            txtScoreIcon.text = ""
            txtScoreIcon.textColor = ThemeManager.currentTheme.SliderTintColor
            let currentTheme = UserDefaults.standard.string(forKey: "CurrentTheme") ?? "IGAPClassic"
            let currentColorSetDark = UserDefaults.standard.string(forKey: "CurrentColorSetDark") ?? "IGAPBlue"
            let currentColorSetLight = UserDefaults.standard.string(forKey: "CurrentColorSetLight") ?? "IGAPBlue"
            
            if currentTheme == "IGAPDay" {
                if currentColorSetLight == "IGAPBlack" {
                    txtScoreIcon.textColor = UIColor.iGapGreen()
                }
            } else if currentTheme == "IGAPNight" {
                if currentColorSetDark == "IGAPBlack" {
                    txtScoreIcon.textColor = UIColor.iGapGreen()
                }
            }
            
        } else if activity.igpScore < 0 { // score down
            txtScoreIcon.text = ""
            txtScoreIcon.textColor = UIColor.iGapRed()
        }
        txtScoreNumber.textColor = ThemeManager.currentTheme.LabelColor
        txtTime.textColor = ThemeManager.currentTheme.LabelColor
        txtTitle.textColor = ThemeManager.currentTheme.LabelColor
    }
}
