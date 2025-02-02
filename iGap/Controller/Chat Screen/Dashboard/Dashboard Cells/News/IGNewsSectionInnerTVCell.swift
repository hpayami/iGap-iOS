//
//  IGNewsSectionInnerTVCell.swift
//  iGap
//
//  Created by BenyaminMokhtarpour on 12/3/19.
//  Copyright © 2019 Kianiranian STDG -www.kianiranian.com. All rights reserved.
//

import UIKit

class IGNewsSectionInnerTVCell: BaseTableViewCell {
    
    @IBOutlet weak var imgNews : UIImageView!
    @IBOutlet weak var lblAgency : UILabel!
    @IBOutlet weak var lblDate : UILabel!
    @IBOutlet weak var lblAlias : UILabel!
    @IBOutlet weak var lblSeenCount : UILabel!
    @IBOutlet weak var bgView : UIView!
    var categoryID : String! = "0"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
        
    }
    
    private func initView() {
        lblAgency.font = UIFont.igFont(ofSize: 12)
        lblDate.font = UIFont.igFont(ofSize: 12)
        lblAlias.font = UIFont.igFont(ofSize: 12)
        lblSeenCount.font = UIFont.igFont(ofSize: 12)
        imgNews.layer.cornerRadius = 5
        bgView.layer.cornerRadius = 5
        
        lblSeenCount.textColor = .white
        initAlignments()
//        self.bgView.backgroundColor = .white
        
        
        lblDate.textColor = ThemeManager.currentTheme.LabelColor
        lblAlias.textColor = ThemeManager.currentTheme.LabelColor
        lblSeenCount.textColor = ThemeManager.currentTheme.LabelColor
        lblDate.textColor = ThemeManager.currentTheme.LabelColor
        bgView.backgroundColor = ThemeManager.currentTheme.TableViewCellColor.darker(by: 20)
    }
    private func initAlignments() {
//        let isEnglish = SMLangUtil.loadLanguage() == SMLangUtil.SMLanguage.English.rawValue
//        imgNews.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
//        lblSeenCount.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
//        lblAlias.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
//        lblDate.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
//        lblAgency.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
        lblSeenCount.textAlignment = .right
        lblAgency.textAlignment = .right
        lblDate.textAlignment = .left
        lblAlias.textAlignment = .right
        
    }
    func setCellData() {
        
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
