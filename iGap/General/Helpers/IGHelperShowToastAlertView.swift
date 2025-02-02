/*
* This is the source code of iGap for iOS
* It is licensed under GNU AGPL v3.0
* You should have received a copy of the license in this archive (see LICENSE).
* Copyright © 2017 , iGap - www.iGap.net
* iGap Messenger | Free, Fast and Secure instant messaging application
* The idea of the Kianiranian STDG - www.kianiranian.com
* All rights reserved.
*/

import IGProtoBuff
import RealmSwift
// IMPORTANT TODO - convert current class to builder
enum helperToastType : Int {
    case alert = 0
    case success = 1
}


class IGHelperShowToastAlertView {
    var tempTimer : Int = 0
    var counter : Timer!
    var popView : UIView!
    let window = UIApplication.shared.keyWindow
    
    static let shared = IGHelperShowToastAlertView()
    //inner view is for adding coonstraint to it
    func showPopAlert(view: UIViewController? = nil,innerView: UIView? = nil,  message: String? = nil, time: CGFloat! = 2.0 , type: helperToastType! = helperToastType.alert ) {
        DispatchQueue.main.async {
            var alertView = view
            if alertView == nil {
                alertView = UIApplication.topViewController()
            }
            self.popView = UIView()
            self.popView.tag = 202
            self.popView.backgroundColor = ThemeManager.currentTheme.BackGroundColor
            self.popView.layer.cornerRadius = 10
            
            switch type {
            case .alert :
                self.popView.layer.borderColor = (ThemeManager.currentTheme.LabelColor.cgColor)
            case .success :
                self.popView.layer.borderColor = (UIColor.iGapGreen().cgColor)
            default :
                break
            }
            self.popView.layer.borderWidth = 1.0
            self.popView.alpha = 0.0
            UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .transitionFlipFromLeft, animations: {

                self.popView.alpha = 1.0
                alertView?.view.addSubview(self.popView)
                self.popView.translatesAutoresizingMaskIntoConstraints = false
                self.popView.heightAnchor.constraint(equalToConstant: 40).isActive = true
                self.popView.rightAnchor.constraint(equalTo: alertView!.view.rightAnchor, constant: -10).isActive = true
                self.popView.leftAnchor.constraint(equalTo: alertView!.view.leftAnchor, constant: 20).isActive = true
                self.popView.bottomAnchor.constraint(equalTo: innerView!.topAnchor, constant: -5).isActive = true
                self.popView.layoutIfNeeded()
            },
                           completion: {(value: Bool) in
            })
            
            
            
            
            
            let lblMessage = UILabel()
            let lblIcon = UILabel()
            lblIcon.textColor = ThemeManager.currentTheme.LabelColor
            lblMessage.textColor = ThemeManager.currentTheme.LabelColor
            lblIcon.font = UIFont.iGapFonticon(ofSize: 20)
            lblIcon.textAlignment = .center
            lblMessage.textAlignment = lblMessage.localizedDirection
            lblMessage.font = UIFont.igFont(ofSize: 15,weight : .light)
            lblMessage.text = message
            switch type {
            case .alert :
                lblIcon.text = ""
            case .success :
                lblIcon.text = ""
            default :
                break
                
            }
            
            
            self.popView.addSubview(lblIcon)
            self.popView.addSubview(lblMessage)
            
            //creat icon label
            lblIcon.translatesAutoresizingMaskIntoConstraints = false
            lblIcon.widthAnchor.constraint(equalToConstant: 25).isActive = true
            lblIcon.heightAnchor.constraint(equalToConstant: 25).isActive = true
            lblIcon.rightAnchor.constraint(equalTo: self.popView.rightAnchor, constant: -10).isActive = true
            lblIcon.centerYAnchor.constraint(equalTo: self.popView.centerYAnchor, constant: 0).isActive = true
            
            
            //creat message label
            lblMessage.translatesAutoresizingMaskIntoConstraints = false
            lblMessage.rightAnchor.constraint(equalTo: lblIcon.leftAnchor, constant: -10).isActive = true
            lblMessage.leftAnchor.constraint(equalTo: self.popView.leftAnchor, constant: 10).isActive = true
            lblMessage.centerYAnchor.constraint(equalTo: self.popView.centerYAnchor, constant: 0).isActive = true
            lblMessage.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Change `time` to the desired number of seconds.
                self.removeAutomatically(view: alertView)
            }
            
            alertView!.view.bringSubviewToFront(self.popView)
        }
        
    }
    private func removeAutomatically(view: UIViewController? = nil) {
        for view in view!.view.subviews {
            if view.tag == 202 {
                UIView.animate(withDuration: 0.2, animations: {view.alpha = 0.0},
                               completion: {(value: Bool) in
                                view.removeFromSuperview()
                })
                
                
                
            }
        }
    }
    
    
    func showPopAlert(view: UIView? = nil,innerView: UIView? = nil,  message: String? = nil, time: CGFloat! = 2.0 , type: helperToastType! = helperToastType.alert ) {
        DispatchQueue.main.async {
            var alertView = view
            if alertView == nil {
                alertView = UIApplication.topViewController()?.view
            }
            self.popView = UIView()
            self.popView.tag = 202
            self.popView.backgroundColor = ThemeManager.currentTheme.BackGroundColor
            self.popView.layer.cornerRadius = 10
            
            switch type {
            case .alert :
                self.popView.layer.borderColor = (ThemeManager.currentTheme.LabelColor.cgColor)
            case .success :
                self.popView.layer.borderColor = (UIColor.iGapGreen().cgColor)
            default :
                break
            }
            self.popView.layer.borderWidth = 1.0
            self.popView.alpha = 0.0
            alertView?.addSubview(self.popView)
            self.popView.translatesAutoresizingMaskIntoConstraints = false
            self.popView.heightAnchor.constraint(equalToConstant: 40).isActive = true
            self.popView.rightAnchor.constraint(equalTo: alertView!.rightAnchor, constant: -10).isActive = true
            self.popView.leftAnchor.constraint(equalTo: alertView!.leftAnchor, constant: 20).isActive = true
            self.popView.bottomAnchor.constraint(equalTo: innerView!.topAnchor, constant: -5).isActive = true
            self.popView.fadeIn(0.2)
            
            let lblMessage = UILabel()
            let lblIcon = UILabel()
            lblMessage.textColor = ThemeManager.currentTheme.LabelColor
            lblIcon.font = UIFont.iGapFonticon(ofSize: 20)
            lblIcon.textAlignment = .center
            lblMessage.textAlignment = lblMessage.localizedDirection
            lblMessage.font = UIFont.igFont(ofSize: 15,weight : .light)
            lblMessage.text = message
            switch type {
            case .alert :
                lblIcon.textColor = ThemeManager.currentTheme.LabelColor
                lblIcon.text = ""
            case .success :
                lblIcon.textColor = UIColor.iGapGreen()
                lblIcon.text = "🌫"
            default :
                break
            }
            
            self.popView.addSubview(lblIcon)
            self.popView.addSubview(lblMessage)
            
            //creat icon label
            lblIcon.translatesAutoresizingMaskIntoConstraints = false
            lblIcon.widthAnchor.constraint(equalToConstant: 25).isActive = true
            lblIcon.heightAnchor.constraint(equalToConstant: 25).isActive = true
            lblIcon.rightAnchor.constraint(equalTo: self.popView.rightAnchor, constant: -10).isActive = true
            lblIcon.centerYAnchor.constraint(equalTo: self.popView.centerYAnchor, constant: 0).isActive = true
            
            //creat message label
            lblMessage.translatesAutoresizingMaskIntoConstraints = false
            lblMessage.centerYAnchor.constraint(equalTo: self.popView.centerYAnchor, constant: 0).isActive = true
            lblMessage.centerXAnchor.constraint(equalTo: self.popView.centerXAnchor, constant: 0).isActive = true
            lblMessage.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Change `time` to the desired number of seconds.
                self.removeAutomatically(view: alertView)
            }
            
            alertView!.bringSubviewToFront(self.popView)
        }
        
    }
    private func removeAutomatically(view: UIView? = nil) {
        for view in view!.subviews {
            if view.tag == 202 {
                UIView.animate(withDuration: 0.2, animations: {view.alpha = 0.0}, completion: {(value: Bool) in
                    view.removeFromSuperview()
                })
            }
        }
    }
}
