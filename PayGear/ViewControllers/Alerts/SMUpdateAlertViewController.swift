//
//  TextFieldAlertViewController.swift
//  PayGear
//
//  Created by amir soltani on 4/30/18.
//  Copyright © 2018 Samsoon. All rights reserved.
//

import UIKit

class SMUpdateAlertViewController: UIViewController {
    
    
   
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: SMBottomButton!
    @IBOutlet weak var dialogTitle: UILabel!
    
    var dialogT : String?
    var message : String?
    var leftButtonTitle:String?
    var rightButtonTitle:String?
    var leftButtonAction: SimpleCallBack?
    var rightButtonAction: CallBack?
    var leftButtonEnable : Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leftButton.setTitle(leftButtonTitle, for: .normal)
        rightButton.setTitle(rightButtonTitle, for: .normal)
        dialogTitle.text = dialogT
        let alignment = SMDirection.TextAlignment()
        dialogTitle.textAlignment = alignment
        if let mess = message {
        messageLabel.text = mess
        }
        rightButton.enable()
        if leftButtonEnable!{
            leftButton.isHidden = false
        }
        else{
             leftButton.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func leftButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        leftButtonAction?()
    }
    @IBAction func rightButtonAction(_ sender: Any) {
        
        rightButtonAction?(true)
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
