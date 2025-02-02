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

class IGOneNewsTVCell: UITableViewCell {

        @IBOutlet weak var lblTitle0 : UILabel!
        @IBOutlet weak var lblTitleTwo0 : UILabel!
        @IBOutlet weak var lblAlias0 : UILabel!
        @IBOutlet weak var imgView0 : UIImageView!
        @IBOutlet weak var bgView0 : UIView!


        var newsOne: [newsInner]!
        var categoryIDOne : String! = "0"
        var categoryOne : String! = ""

        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
            initView()
        }
        static var nib: UINib {
            return UINib(nibName: identifier, bundle: nil)
        }
        
        static var identifier: String {
            return String(describing: self)
        }

        private func initView() {
            lblAlias0.font = UIFont.igFont(ofSize: 12)
            lblTitle0.font = UIFont.igFont(ofSize: 12)
            lblTitleTwo0.font = UIFont.igFont(ofSize: 12)
            imgView0.layer.cornerRadius = 5
            bgView0.layer.cornerRadius = 5

            initAlignments()
        }
        private func initAlignments() {
             let isEnglish = SMLangUtil.loadLanguage() == SMLangUtil.SMLanguage.English.rawValue
                imgView0.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
                lblTitle0.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
                lblTitleTwo0.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
                lblAlias0.transform = isEnglish ? CGAffineTransform.identity : CGAffineTransform(scaleX: -1, y: 1)
            lblTitle0.textAlignment = .right
            lblTitleTwo0.textAlignment = .right
            lblAlias0.textAlignment = .right


        }
        func setCellData() {
            self.bgView0.backgroundColor = UIColor.hexStringToUIColor(hex: newsOne[0].color!)
            let urlStringFirst = newsOne[0].contents?.image![0].Original
            let urlFirst = URL(string: urlStringFirst!)
            //set images of double news Titles
            imgView0.sd_setImage(with: urlFirst, placeholderImage: UIImage(named :"1"), completed: nil)
            //set Color of double news Titles
            lblTitle0.textColor = UIColor.hexStringToUIColor(hex: newsOne[0].colorTitr!)
            lblTitleTwo0.textColor = UIColor.hexStringToUIColor(hex: newsOne[0].colorTitr!)
            lblAlias0.textColor = UIColor.hexStringToUIColor(hex: newsOne[0].colorRooTitr!)
            //set text of double news RooTitr
            if newsOne[0].contents?.titr == nil || newsOne[0].contents?.titr == "" {
                lblTitleTwo0.isHidden = true
                //set text of double news Alias
                lblAlias0.text = newsOne[0].contents?.lead

            } else {
                lblTitleTwo0.isHidden = false
                lblTitleTwo0.text = newsOne[0].contents?.titr
                //set text of double news Alias
                lblAlias0.text = newsOne[0].contents?.lead

            }

        }
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            // Configure the view for the selected state
        }
        
    @IBAction func didTapOnNews(_ sender: UIButton) {
        let newsInner = IGNewsSectionInnerTableViewController.instantiateFromAppStroryboard(appStoryboard: .News)
        
            newsInner.categoryID = categoryIDOne
            newsInner.category = categoryOne

        UIApplication.topViewController()!.navigationController!.pushViewController(newsInner, animated: true)
        
    }

    }
