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
import SwiftProtobuf
import IGProtoBuff
import MBProgressHUD

class IGSettingPrivacyAndSecurityTwoStepVerificationChangeHintTableViewController: UITableViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var hintTextField: UITextField!
    @IBOutlet weak var txtHint: UITextField!
    @IBOutlet weak var lbl1: UILabel!
    var password: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: IGStringsManager.GlobalDone.rawValue.localized, title: IGStringsManager.ChangeHint.rawValue.localized)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        navigationItem.rightViewContainer?.addAction {
            self.changeHint()
        }
        lbl1.text = IGStringsManager.InvalidHint.rawValue.localized
        txtHint.placeholder = IGStringsManager.Optional.rawValue.localized
    }
    
    func changeHint(){
        
        if txtHint.text == nil {
            let alert = UIAlertController(title: "Error", message: "Please First Write Your Hint!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        IGUserTwoStepVerificationChangehintRequest.Generator.generate(hint: txtHint.text!, password: password!).success({ (protoResponse) in
            DispatchQueue.main.async {
                hud.hide(animated: true)
                switch protoResponse {
                case let unsetPassword as IGPUserTwoStepVerificationChangeHintResponse:
                    hud.hide(animated: true)
                    IGUserTwoStepVerificationChangehintRequest.Handler.interpret(response: unsetPassword)
                    self.navigationController?.popViewController(animated: true)
                default:
                    break
                }
            }
        }).error ({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .timeout:
                    break
                case .userTwoStepVerificationChangeHintMaxTryLock:
                    let alert = UIAlertController(title: "Error", message: "Max Try Lock", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    break
                default:
                    break
                }
                hud.hide(animated: true)
            }
        }).send()
    }
}
