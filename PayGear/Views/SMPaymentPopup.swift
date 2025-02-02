//
//  SMPaymentPopup.swift
//  PayGear
//
//  Created by Fatemeh Shapouri on 4/23/18.
//  Copyright © 2018 Samsoon. All rights reserved.
//

import UIKit
import webservice
import BetterSegmentedControl

///Protocol to observe some actions implemented by user class
protocol SMPaymentPopupDelegate {
    func dismissPopup()
}

// MARK: - extention to implement protocol method
/// Avoid crash when owner class is not implemented protocol method
extension SMPaymentPopupDelegate {
    func dismissPopup(){
        // leaving this empty
    }
}
/// Popup to confirm payment, this view shows some breif information about receiver and
/// let user make some change on payment amount in some cases; (if user make a transaction from message
/// the amount value is not editable) In Payment from user to merchant this dialog shows merchant information too
class SMPaymentPopup: UIView, SMStepperDelegate,UITextFieldDelegate {
    
    var delegate: SMPaymentPopupDelegate!
	var keyboardHeight : CGFloat?
    var paygearCard: SMCard?

    /// Height Constraint of popup
    @IBOutlet var popupHeightConstraint: NSLayoutConstraint!
	/// Height Constraint of stepper
    @IBOutlet var stepperHeightConstraint: NSLayoutConstraint!
	/// Height Constraint of driver label
    @IBOutlet var driverNameHeightConstraint: NSLayoutConstraint!
	
    @IBOutlet var popupView: UIView!
	
	@IBOutlet var merchantInfoView: UIView!
    @IBOutlet var merchantTypeLogo: UIImageView!
    @IBOutlet var merchantTypeName: UILabel!
    @IBOutlet var merchantTypeDescription: UILabel!
	
	/// In taxi (khati) type the driver name will be shown
	@IBOutlet var driverName: UILabel!
	
	/// In taxi (khati) type this stepper let user  select of number of
	// passenger to increase amount of payment automatically
    @IBOutlet var passengerStepper: SMStepper!
	
	@IBOutlet var amountInfoView: UIView!
    @IBOutlet var amountTF: UITextField!
	@IBOutlet var currency: UILabel!
	
	/// Let user payment type, It would be pay by wallet or by bank card
    @IBOutlet var paymentTypeSwitch: BetterSegmentedControl!
	
    @IBOutlet public var confirmBtn: SMBottomButton!
	
	
	public var currentAmount = 0
    /// Popup type (the visible item changed)
    public var type: SMAmountPopupType = .PopupNoProductTaxi {
        didSet{
            if type == .PopupNoProductTaxi {
                
                popupHeightConstraint.constant = 300
                stepperHeightConstraint.constant = 0
                passengerStepper.isHidden = true
                amountTF.isEnabled = true
            }
            else if type == .PopupProductedTaxi {

            }
            else  {
		
                popupHeightConstraint.constant = 250
                stepperHeightConstraint.constant = 0
                driverNameHeightConstraint.constant = 0
                passengerStepper.isHidden = true
                amountTF.isEnabled = true
                driverName.isHidden = true
                
            }
        }
    }
	
    /// Dictionary contains name, productName, subTitle, price, imagePath
    public var value: [String: String]! {
        didSet {
			
            if type == .PopupNoProductTaxi {
                
                merchantTypeName.text = value["subTitle"]?.inLocalizedLanguage()
                merchantTypeDescription.isHidden = true
                driverName.text = "\("merchant".localized) \(value["name"] ?? "unknown".localized)"
                
                
            }
            else if type == .PopupProductedTaxi {
                
                amountTF.text = value["price"]?.inRialFormat().inLocalizedLanguage()
                merchantTypeName.text = value["subTitle"]?.inLocalizedLanguage()
                merchantTypeDescription.text = value["productName"]?.inLocalizedLanguage()
                driverName.text = "\("merchant".localized) \(value["name"] ?? "unknown".localized)".inLocalizedLanguage()
                
            }
            else if type == .PopupUser {
                
                merchantTypeName.text = "PayTo".localized
                merchantTypeDescription.text = value["name"]
				
				if let price = value["price"] {
					amountTF.text = price as String
					amountTF.isEnabled = false
				}
            }
            
            DispatchQueue.main.async {
                let request = WS_methods(delegate: self, failedDialog: true)
                let str = request.fs_getFileURL(self.value["imagePath"])
                self.merchantTypeLogo.downloadedFrom(link: str!.filter { !" \\ \n \" \t\r".contains($0) },contentMode : .scaleAspectFill)
                self.merchantTypeLogo.layer.cornerRadius = self.merchantTypeLogo.bounds.width/2
                self.merchantTypeLogo.layer.borderWidth = 1
                self.merchantTypeLogo.layer.borderColor = UIColor.black.cgColor
                self.merchantTypeLogo?.layer.shadowRadius = 10
                self.merchantTypeLogo?.layer.shadowColor = UIColor.black.cgColor
                self.merchantTypeLogo?.layer.shadowOffset = CGSize(width: 0, height: 1)
                self.merchantTypeLogo?.layer.shadowOpacity = 0.5
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Class function to load view from nib file
    ///
    /// - Returns: instance of SMPaymentPopup
    class func loadFromNib() -> SMPaymentPopup {
        return UINib(nibName: "SMPaymentPopup", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SMPaymentPopup
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        for card in SMCard.getAllCardsFromDB() {
            if card.type == 1 {
                self.paygearCard = card
            }
        }
    }
    
    
    /// Set layout after loading view
    public override func layoutSubviews() {
        super.layoutSubviews()
		
		//Below actions define view language and view direction by current language
		let transform = SMDirection.PageAffineTransform()
		self.transform = transform
		currency.transform = transform
		amountTF.transform = transform
		passengerStepper.transform = transform
		driverName.transform = transform
		merchantTypeName.transform = transform
		merchantTypeDescription.transform = transform
		paymentTypeSwitch.transform = transform
		confirmBtn.transform = transform
		
		let direction = SMDirection.TextAlignment()
		driverName.textAlignment = direction
		merchantTypeName.textAlignment = direction
		merchantTypeDescription.textAlignment = direction
		
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        self.frame = UIApplication.shared.keyWindow!.frame
        popupView.layer.cornerRadius = 12
        merchantInfoView.layer.cornerRadius = 12
		paymentTypeSwitch.addTarget(self, action: #selector(self.segmentValueChanged(_:)), for: .valueChanged)
		paymentTypeSwitch.options = [
		.titleFont(SMFonts.IranYekanLight(15.0)),
		.selectedTitleFont(SMFonts.IranYekanBold(14.0))]
		paymentTypeSwitch.titles = ["credit".localized ,"card".localized]

        amountInfoView.layer.borderColor = UIColor(netHex: 0xb2bec4).cgColor
        amountInfoView.layer.cornerRadius = 12
        amountInfoView.layer.borderWidth = 1
		amountTF.inputView =  LNNumberpad.default()
        passengerStepper.delegate = self
		
        confirmBtn.layer.cornerRadius = confirmBtn.frame.height/2
        confirmBtn.isEnabled = true
		
		confirmBtn.setTitle("pay".localized, for: .normal)
		currency.text = "Currency".localized
		
    }
    
	/// Add self to view controller, each viewcontroller want to show this view
	/// must call this method
	/// - Parameter viewController: the view controller which present popup
	public func showPopup(viewController: UIViewController) {
        
//        let window = UIApplication.shared.keyWindow!
//        window.addSubview(self)
        amountTF.delegate = self
		viewController.view.addSubview(self)
        
    }
	
	@objc func segmentValueChanged(_ sender: Any) {
		SMLog.SMPrint("value changed")
	}
    
    @IBAction func viewDidTap(_ sender: Any) {
		dismiss()
    }
	
	func dismiss() {
		self.removeFromSuperview()
		if delegate != nil {
			delegate.dismissPopup()
		}
	}
    
    /// The number of unit value is changed, this function calculate the amount value according
	/// to the unit and multiple amount; if calculated amount is more than user wallet amount
	/// the payment type goes to change to card
    func stepperValueDidChanged () {
        amountTF.text = "\(Int(value["price"]!)! * passengerStepper.value)".inRialFormat().inLocalizedLanguage()
		
		if  currentAmount > Int(value["price"]!)! * passengerStepper.value  {
			do {
				try paymentTypeSwitch.setIndex(0, animated: true)
			}
			catch {
				
			}
		}
		else  {
			do {
				try paymentTypeSwitch.setIndex(1, animated: true)
			}
			catch {
				
			}
		}
    }
    
    
    /// Hide stepper when value is customizing
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if type == .PopupProductedTaxi && passengerStepper.frame.height != 0{
            UIView.animate(withDuration: 0.2, animations:{

                self.passengerStepper.alpha = 0
                
            }, completion:{ y in

            })
        }
        
        
        var newStr = string
       // Force text field to get only digit characters
        newStr = (textField.text! as NSString).replacingCharacters(in: range, with: newStr).onlyDigitChars()
        textField.text = newStr == "" ? "" : newStr.onlyDigitChars().inRialFormat().inLocalizedLanguage()
        
        // change segment controll to cart if amount is higher than user balance
        if Int64(newStr) ?? 0 > (paygearCard?.balance ?? 0) {
            if paymentTypeSwitch.index != 1 {
                do {
                    try paymentTypeSwitch.setIndex(1, animated: true)
                }
                catch { }
            }
            
        } else {
            if paymentTypeSwitch.index != 0 {
                do {
                    try paymentTypeSwitch.setIndex(0, animated: true)
                }
                catch { }
            }
        }
        
        if string == "" && range.location < textField.text!.length{
            let position = textField.position(from: textField.beginningOfDocument, offset: range.location)!
            textField.selectedTextRange = textField.textRange(from: position, to: position)
        }
		
        return false
    }
    
    
    /// Change position of popup by keyboard size
    func refreshPopupPosition(){
        
        if popupView.frame.intersects(CGRect(x: 0, y: self.bounds.height - keyboardHeight! , width: self.bounds.width, height: keyboardHeight!)) {
		SMLog.SMPrint("true")
		var topPadding : CGFloat = 0
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.keyWindow
                topPadding = (window?.safeAreaInsets.top)!
            }
            var frame =  popupView.frame
            frame.origin.y = 60 + topPadding
            popupView.frame = frame
        }
    }
    
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo!
        keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        refreshPopupPosition()
        self.layoutIfNeeded()
    }
    
    @objc
    func keyboardWillHide(notification: NSNotification) {
        self.layoutIfNeeded()

    }
}
