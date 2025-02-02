//
//  IGInternetPackageViewController.swift
//  iGap
//
//  Created by MacBook Pro on 6/21/1398 AP.
//  Copyright © 1398 AP Kianiranian STDG -www.kianiranian.com. All rights reserved.
//

import UIKit

class IGInternetPackageViewController: BaseViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var edtPhoneNubmer: UITextField!
    @IBOutlet weak var packageTypeLbl: UILabel!
    @IBOutlet weak var typeTimeLbl: UILabel!
    @IBOutlet weak var timeCheckMarkBtn: UIButton!
    @IBOutlet weak var typeVolumeLbl: UILabel!
    @IBOutlet weak var volumeCheckMarkBtn: UIButton!
    @IBOutlet weak var selectTimeOrVolumeBtn: UIButton!
    @IBOutlet weak var selectPackageBtn: UIButton!
    
    @IBOutlet weak var btnBuy: UIButton!
    
    // MARK: - Variables
    let PHONE_LENGTH = 11
    var latestPhoneNumber = ""
    var dispatchGroup: DispatchGroup!
    
    var internetCategories: [IGStructInternetCategory]!
    var internetPackages: IGStructInternetPackageCategorized!
    
    var selectedCategory: IGStructInternetCategory?
    var selectedPackage: IGStructInternetPackage?
    
    var operatorDictionary: [String : IGOperator] = [
        "0910" : IGOperator.mci,
        "0911" : IGOperator.mci,
        "0912" : IGOperator.mci,
        "0913" : IGOperator.mci,
        "0914" : IGOperator.mci,
        "0915" : IGOperator.mci,
        "0916" : IGOperator.mci,
        "0917" : IGOperator.mci,
        "0918" : IGOperator.mci,
        "0919" : IGOperator.mci,
        "0990" : IGOperator.mci,
        "0991" : IGOperator.mci,
        "09930": IGOperator.mci,
        "09931": IGOperator.mci,
        
        "0901" : IGOperator.irancell,
        "0902" : IGOperator.irancell,
        "0903" : IGOperator.irancell,
        "0930" : IGOperator.irancell,
        "0933" : IGOperator.irancell,
        "0935" : IGOperator.irancell,
        "0936" : IGOperator.irancell,
        "0937" : IGOperator.irancell,
        "0938" : IGOperator.irancell,
        "0939" : IGOperator.irancell,
        
        "0920" : IGOperator.rightel,
        "0921" : IGOperator.rightel,
        "0922" : IGOperator.rightel
    ]
    
    var operatorType: IGOperator!

    override func viewDidLoad() {
        super.viewDidLoad()

        getData()
        edtPhoneNubmer.delegate = self
                
        manageButtonsView(buttons: [selectTimeOrVolumeBtn, selectPackageBtn, btnBuy])
        
        setContentVisibility(isHidden: true)
        
        self.view.semanticContentAttribute = self.semantic
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initCHangeLang()
        initNavigationBar(title: IGStringsManager.BuyInternetPackage.rawValue.localized) {}
    }
    
    
    private func setContentVisibility(isHidden: Bool) {
        self.edtPhoneNubmer.isHidden = isHidden
        self.packageTypeLbl.isHidden = isHidden
        self.typeTimeLbl.isHidden = isHidden
        self.typeVolumeLbl.isHidden = isHidden
        self.timeCheckMarkBtn.isHidden = isHidden
        self.volumeCheckMarkBtn.isHidden = isHidden
        self.selectTimeOrVolumeBtn.isHidden = isHidden
        self.selectPackageBtn.isHidden = isHidden
        self.btnBuy.isHidden = isHidden
    }
    
    private func getData(opType : IGOperator = .mci) {
    }
    
    func initCHangeLang() {
        packageTypeLbl.text = IGStringsManager.PackageType.rawValue.localized
        
        typeTimeLbl.text = IGStringsManager.Time.rawValue.localized
        typeVolumeLbl.text = IGStringsManager.Voloume.rawValue.localized
        
        edtPhoneNubmer.placeholder = IGStringsManager.MobileNumber.rawValue.localized
        self.selectTimeOrVolumeBtn.setTitle(IGStringsManager.ChooseTime.rawValue.localized, for: .normal)
        self.selectPackageBtn.setTitle(IGStringsManager.PackageType.rawValue.localized, for: .normal)
        self.btnBuy.setTitle(IGStringsManager.Buy.rawValue.localized, for: .normal)
    }
    
    private func manageButtonsView(buttons: [UIButton]) {
        for btn in buttons {
            //btn.removeUnderline()
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 0.2
            btn.layer.borderColor = ThemeManager.currentTheme.LabelGrayColor.cgColor
        }
    }
    
    private func showModalAlertView(
        title: String,
        message: String?,
        categories: [IGStructInternetCategory] = [], showPackages: Bool = false,
        categoryAlertClouser: ((_ category : IGStructInternetCategory, _ action: UIAlertAction) -> Void)?,
        packageAlertClouser: ((_ package : IGStructInternetPackage) -> Void)?,
        hasCancel: Bool = true)
    {
        let option = UIAlertController(title: title, message: message, preferredStyle: IGGlobal.detectAlertStyle())
        
        for category in categories {
            let action = UIAlertAction(title: "\(category.category!.value!)".inLocalizedLanguage() + " " + category.category!.subType!.localized, style: .default, handler: { (action) in
                categoryAlertClouser!(category, action)
            })
            
//            let attributedText = NSMutableAttributedString(string: subtitle)
//            let range = NSRange(location: 0, length: attributedText.length)
//            attributedText.addAttribute(NSAttributedString.Key.kern, value: 1.5, range: range)
//            attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont.igFont(ofSize: 18), range: range)
            
//            action.setValue(UIColor.darkGray, forKey: "titleTextColor")
            option.addAction(action)
            
            // this has to be set after presenting the alert, otherwise the internal property __representer is nil
//            guard let label = action.value.value(forKey: "label") as? UILabel else { return }
//            label.attributedText = attributedText
        }
        
        if showPackages {
            let packages: [IGStructInternetPackage]!
            if isTimeChecked {
                packages = internetPackages.data?.filter({ $0.duration == selectedCategory!.id })
            } else {
                packages = internetPackages.data?.filter({ $0.traffic == selectedCategory!.id })
            }
            
            for package in packages {
                let desc = package.description ?? ""
                let title = desc + " " + "\(package.cost ?? 0)".onlyDigitChars().inRialFormat() + " " + IGStringsManager.Currency.rawValue.localized
                let action = UIAlertAction(title: title, style: .default, handler: { (action) in
                    packageAlertClouser!(package)
                })
                option.addAction(action)
            }
        }
        
        let cancel = UIAlertAction(title: IGStringsManager.GlobalCancel.rawValue.localized, style: .cancel, handler: nil)
        
//        cancel.setValue(UIColor.darkGray, forKey: "titleTextColor")
        option.addAction(cancel)
        
        self.present(option, animated: true, completion: {})
    }
    
    
    // MARK: - Actions
    
    var isTimeChecked: Bool = true
    @IBAction func timeCheckmarkClicked(_ sender: UIButton) {
        if !isTimeChecked {
            // is not checked so check time checkmark
            timeCheckMarkBtn.setTitle("CHECKED_ICON".Imagelocalized, for: .normal)
            timeCheckMarkBtn.setTitleColor(#colorLiteral(red: 0.2549019608, green: 0.6941176471, blue: 0.1254901961, alpha: 1), for: .normal)
            self.selectTimeOrVolumeBtn.setTitle(IGStringsManager.ChooseTime.rawValue.localized, for: .normal)
            self.selectedCategory = nil
            self.selectPackageBtn.isHidden = true
            
            // uncheck volume checkmark
            volumeCheckMarkBtn.setTitle("NOT_CHECKED_ICON".Imagelocalized, for: .normal)
            volumeCheckMarkBtn.setTitleColor(#colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1), for: .normal)
        }
        isTimeChecked = true
    }
    
    @IBAction func volumeCheckmarkClicked(_ sender: UIButton) {
        if isTimeChecked {
            // if is not checked -> check it
            volumeCheckMarkBtn.setTitle("CHECKED_ICON".Imagelocalized, for: .normal)
            volumeCheckMarkBtn.setTitleColor(#colorLiteral(red: 0.2549019608, green: 0.6941176471, blue: 0.1254901961, alpha: 1), for: .normal)
            self.selectTimeOrVolumeBtn.setTitle(IGStringsManager.Voloume.rawValue.localized, for: .normal)
            self.selectedCategory = nil
            self.selectPackageBtn.isHidden = true
            
            // uncheck time checkmark
            timeCheckMarkBtn.setTitle("NOT_CHECKED_ICON".Imagelocalized, for: .normal)
            timeCheckMarkBtn.setTitleColor(#colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1), for: .normal)
        }
        isTimeChecked = false
    }
    
    @IBAction func chooseTimeOrVolumeTappd(_ sender: UIButton) {
        
        var categories = [IGStructInternetCategory]()
        
        if isTimeChecked {
            categories = internetCategories.filter({ $0.category?.type == .duration })
        } else {
            categories = internetCategories.filter({ $0.category?.type == .traffic })
        }
        
        showModalAlertView(title: selectTimeOrVolumeBtn.titleLabel!.text!, message: nil, categories: categories, categoryAlertClouser: { (category, action) -> Void in
            
            self.selectedCategory = category
            self.selectTimeOrVolumeBtn.setTitle(action.title, for: .normal)
            self.selectPackageBtn.isHidden = false
            self.selectPackageBtn.setTitle(IGStringsManager.PackageType.rawValue.localized, for: .normal)
            self.selectedPackage = nil
            self.view.endEditing(true)
        }, packageAlertClouser: nil)
    }
    
    @IBAction func choosePackageTappd(_ sender: UIButton) {
        guard let _ = self.selectedCategory else { return }
        
        showModalAlertView(title: selectPackageBtn.titleLabel!.text!, message: nil, showPackages: true, categoryAlertClouser: nil, packageAlertClouser: { (package) in
            
            self.selectedPackage = package
            self.selectPackageBtn.setTitle(package.description, for: .normal)
            self.btnBuy.isHidden = false
            self.view.endEditing(true)
        })
    }
    
    @IBAction func payBtnTappd(_ sender: UIButton) {
    }
    
    
    // MARK: - textfiel function override
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = edtPhoneNubmer.text?.inEnglishNumbersNew() {
            let newLength = text.count + string.count - range.length
            if (newLength == PHONE_LENGTH) {
                operatorType = operatorDictionary[text.substring(offset: 4)]
                
//                if operatorType != .mci {
//                    self.view.endEditing(true)
//                    IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.OnlyMCI.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
//
//                    return true
//                }
                
                switch operatorType {
                case .mci : getData(opType: .mci)
                case .irancell : getData(opType: .irancell)
                case .rightel : getData(opType: .rightel)
                default: break
                }
                latestPhoneNumber = text
                
                self.packageTypeLbl.isHidden = false
                self.typeTimeLbl.isHidden = false
                self.typeVolumeLbl.isHidden = false
                self.timeCheckMarkBtn.isHidden = false
                self.volumeCheckMarkBtn.isHidden = false
                self.selectTimeOrVolumeBtn.isHidden = false
                
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5){
                    self.view.endEditing(true)
                }
            } else if (newLength > PHONE_LENGTH) {
                edtPhoneNubmer.text = latestPhoneNumber
            } else {
                latestPhoneNumber = text
            }
        }
        return true
    }

}
