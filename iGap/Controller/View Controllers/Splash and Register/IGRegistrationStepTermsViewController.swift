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
import MBProgressHUD
import IGProtoBuff
import WebKit

class IGRegistrationStepTermsViewController: MainViewController {
    
    @IBOutlet weak var webView: WKWebView!
    var showNav : Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        if showNav {
            let navItem = self.navigationItem as! IGNavigationItem
            navItem.addModalViewItems(leftItemText: nil, rightItemText: IGStringsManager.GlobalDone.rawValue.localized, title: IGStringsManager.TermsAndConditions.rawValue.localized)
            navItem.rightViewContainer?.addAction {
                self.dismiss(animated: true) {
                    
                }
            }
        } else {
            initCustomtNav(title: IGStringsManager.TermsAndConditions.rawValue.localized, font: UIFont.igFont(ofSize: 15))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        IGInfoPageRequest.Generator.generate(pageID: "TOS").success { (responseProto) in
            DispatchQueue.main.async {
                switch responseProto {
                case let pageInfoResponse as IGPInfoPageResponse:
                    let body = IGInfoPageRequest.Handler.interpret(response: pageInfoResponse)
                    let htmlString = "<font face='IRANSans' size='3'>" + "<p style='text-align:center'>" + body + "</p>"
                    
                    if SMLangUtil.loadLanguage() == "fa" {
                        
                        self.webView.loadHTMLString(htmlString.replacingOccurrences(of: "justify", with: "right"), baseURL: nil)

                    }
                    else {
                        self.webView.loadHTMLString(htmlString.replacingOccurrences(of: "justify", with: "left"), baseURL: nil)

                    }
                default:
                    break
                }
                hud.hide(animated: true)
            }
            }.error { (errorCode, waitTime) in
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                }
            }.send()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
