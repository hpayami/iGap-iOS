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

class customYearTextfield: UITextField, UITextFieldDelegate {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)
        
//                delegate = self
    }
    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)
        
        //        delegate = self
    }
    @objc func myTextFieldDidChange(_ textField: UITextField) {
        
        if let amountString = textField.text {
            if amountString.count <= 2 {
                textField.text = amountString.trimmingCharacters(in: .whitespaces).inLocalizedLanguage()

            }
            else {
                textField.deleteBackward()

            }
        }
        
    }

    
}
