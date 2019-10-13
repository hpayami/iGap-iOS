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
import webservice

var currentBussinessType = 3
var merchantID : String = ""
var merchantBalance : String = "0"
var currentRole = "paygearuser"

var needToUpdate = false

protocol HandlePassBalance {
    func sendBalanceToScannerVC(cardBalance: String)
}
class packetTableViewController: BaseTableViewController , HandleDefaultCard,UICollectionViewDelegate , UICollectionViewDataSource {
    var shouldShowHisto = false
    var merchant : SMMerchant!
    var layout =  UICollectionViewFlowLayout()
    var delegate: HandlePassBalance? = nil

    @IBOutlet weak var barcodeQrwidth: NSLayoutConstraint!
    @IBOutlet weak var lblWalletBalance : UILabel!
    @IBOutlet weak var lblCurrencyFormat : UILabel!
    @IBOutlet weak var lblMyHistoryTitle : UILabel!
    @IBOutlet weak var lblMyCards: UILabel!
    @IBOutlet weak var btnCashout: UIButtonX!
    @IBOutlet weak var btnHisto: UIButton!
    @IBOutlet weak var btnQrCodeScan: UIButton!
    @IBOutlet weak var btnCharge: UIButtonX!
    
    var bussinessArray : [Int]! = []
    var showSection: Bool = true
    var selectedRow: Int = 0

    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    var items: [[DropdownItem]]!
    var otheritems: [DropdownItem] = []
    var Taxyitems: [DropdownItem] = []
    var Merchantitems: [DropdownItem] = []

    
    
    var cellHeight : Int = 270
    var StaticCellHeight : Int = 130
    var plusValue : Int = 0
    var hasValue = false
    var bank = SMBank()
    var defaultHeightSize : Int = 0
    var defaultCelltSize : Int = 0
    var defaultWidthSize : Int = 0
    @IBOutlet weak var cardCollectionView: UICollectionView!
    func valueChanged(value: Bool) {
        
    }
    
    
    @IBOutlet weak var lblCurrency: UILabel!
    
    var userCards: [SMCard]?
    var merchantCard : SMCard?

    //MARK:-ARRAYS FOR BANK CARDS
    var stringImgArray = [String]()
    var stringCardNumArray = [String]()
    var stringBankCodeArray = [Int64]()
    var stringBankLogoArray = [String]()
    var stringBankNameArray = [String]()
    var stringCardTokenArray = [String]()
    var stringCardTypeArray = [Int64]()
    var indexOfCardsWithEmptyBG = [Int]()
    var stringCardisDefaultArray = [Bool]()

    //MARK:-ARRAYS FOR CLUB CARDS
    var stringClubAmountsArray = [Int64]()


    var userMerchants: [SMMerchant]?

    override func viewDidLoad() {
        super.viewDidLoad()
        isfromPacket = false
        btnCashout.backgroundColor = .iGapGreen()
        btnCharge.backgroundColor = .iGapGreen()
        btnCashout.isUserInteractionEnabled = true

        initNavigationBar()
        defaultHeightSize = Int(cardCollectionView.frame.height)
        print(defaultHeightSize)
        defaultWidthSize = Int(cardCollectionView.frame.width)
        self.tableView.backgroundColor = UIColor(named: themeColor.backgroundColor.rawValue)
        DispatchQueue.main.async {
            SMLoading.hideLoadingPage()
        }
        IGHelperTracker.shared.sendTracker(trackerTag: IGHelperTracker.shared.TRACKER_WALLET_PAGE)
        self.initFont()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldShowHisto = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        callRefreshToken()
        finishDefault(isPaygear: true, isCard: false)
        initCollectionView()
        currentRole = "paygearuser"

       self.setupUI()
        self.view.layoutIfNeeded()
        self.btnCharge.layoutIfNeeded()
       SMCard.updateBaseInfoFromServer()

        
    }
    private func initFont() {
        btnHisto.titleLabel?.font = UIFont.iGapFonticon(ofSize: 27)
        btnQrCodeScan.titleLabel?.font = UIFont.iGapFonticon(ofSize: 27)
        btnHisto.setTitle("", for: .normal)
        btnQrCodeScan.setTitle("", for: .normal)

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isfromPacket = true

        btnCashout.backgroundColor = .iGapGreen()
        btnCharge.backgroundColor = .iGapGreen()
        btnCashout.isUserInteractionEnabled = true

        merchantID = SMUserManager.accountId
        getMerchantData()
        initChangeLanguage()
        IGRequestWalletGetAccessToken.sendRequest()
        btnCashout.backgroundColor = .iGapGreen()
        btnCharge.backgroundColor = .iGapGreen()

        
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        
        let p = gesture.location(in: self.cardCollectionView)
        print(p)
        if let indexPath = self.cardCollectionView.indexPathForItem(at: p) {
            // get the cell at indexPath (the one you long pressed)
            let cell = self.cardCollectionView.cellForItem(at: indexPath)
            // do stuff with the cell
            print(cell?.frame.height)

            print("cell selected index is :",indexPath)
        } else {
            print("couldn't find index path")
        }
    }
    //MARK: change Language Handler
    func initChangeLanguage() {
        //        UIView.appearance().semanticContentAttribute = .forceRightToLeft
        lblWalletBalance.text = SMLangUtil.changeLblText(tag: lblWalletBalance.tag, parentViewController: NSStringFromClass(self.classForCoder))
        lblWalletBalance.textAlignment = self.TextAlignment
        lblMyCards.text = SMLangUtil.changeLblText(tag: lblMyCards.tag, parentViewController: NSStringFromClass(self.classForCoder))
        lblCurrencyFormat.text = SMLangUtil.changeLblText(tag: lblCurrencyFormat.tag, parentViewController: NSStringFromClass(self.classForCoder))
        btnCashout.setTitle(SMLangUtil.changeLblText(tag: btnCashout.tag, parentViewController: NSStringFromClass(self.classForCoder)), for: .normal)
        btnCharge.setTitle(SMLangUtil.changeLblText(tag: btnCharge.tag, parentViewController: NSStringFromClass(self.classForCoder)), for: .normal)
        lblMyHistoryTitle.text = "MONEY_TRANSFER_HISTORY".localizedNew
    }
    
    func initView() {
        
        hasShownQrCode = false
        let settingItem = UIBarButtonItem.init(image: UIImage(named: "settings"), style: .done, target: self, action: #selector(showSetting))
        let receiverItem = UIBarButtonItem.init(image: UIImage(named: "store"), style: .done, target: self, action: #selector(showReceivers))
        if userMerchants?.count != nil {
            if (userMerchants?.count)! > 1  {
                
                if currentRole == "admin" || currentRole == "paygearuser" {
                    self.navigationItem.rightBarButtonItems = [settingItem , receiverItem]
                    if currentRole == "paygearuser" {
                        barcodeQrwidth.constant = 47.0
//                        self.btnQrCodeScan.layoutIfNeeded()
                        self.view.layoutIfNeeded()

                    }
                    if currentRole == "admin" {
                        barcodeQrwidth.constant = 0.0
//                        self.btnQrCodeScan.layoutIfNeeded()
                        self.view.layoutIfNeeded()

                    }
                }
                else {
                    self.navigationItem.rightBarButtonItems = [receiverItem]
                    barcodeQrwidth.constant = 0.0
//                    self.btnQrCodeScan.layoutIfNeeded()
                    self.view.layoutIfNeeded()

                }
            }
            else {
                self.navigationItem.rightBarButtonItems = [settingItem]
                barcodeQrwidth.constant = 0.0
//                self.btnQrCodeScan.layoutIfNeeded()
                self.view.layoutIfNeeded()

            }
            
        }



    }
    func setupUI() {
        switch currentRole {
        case "paygearuser" :
            self.btnCharge.isHidden = false
            self.btnCashout.isHidden = false
            self.btnHisto.isHidden = false
            self.lblWalletBalance.text = "TTL_WALLET_BALANCE_USER".localizedNew
            self.btnCashout.setTitle("BTN_CASHOUT_WALLET".localizedNew, for: .normal)
            initView()
            self.view.layoutIfNeeded()
            DispatchQueue.main.async {
                SMLoading.hideLoadingPage()
                
            }
            break
        case "admin" :
            self.btnCharge.isHidden = true
            self.btnCashout.isHidden = false
            self.btnHisto.isHidden = true
            if currentBussinessType == 0 {
                self.lblWalletBalance.text = "TTL_WALLET_BALANCE_STORE".localizedNew
                self.btnCashout.setTitle("BTN_CASHOUT_WALLET_STORE".localizedNew, for: .normal)
            }
            if currentBussinessType == 2 {
                self.btnCashout.setTitle("BTN_CASHOUT_WALLET_DRIVER".localizedNew, for: .normal)
                self.lblWalletBalance.text = "TTL_WALLET_BALANCE_DRIVER".localizedNew

            }
            initView()
            self.view.layoutIfNeeded()
            DispatchQueue.main.async {
                SMLoading.hideLoadingPage()
                
            }
            break
        case "finance" :
            self.btnCharge.isHidden = true
            self.btnCashout.isHidden = true
            self.btnHisto.isHidden = true
            if currentBussinessType == 0 {
                self.lblWalletBalance.text = "TTL_WALLET_BALANCE_STORE".localizedNew
                self.btnCashout.setTitle("BTN_CASHOUT_WALLET_STORE".localizedNew, for: .normal)
            }
            if currentBussinessType == 2 {
                self.btnCashout.setTitle("BTN_CASHOUT_WALLET_DRIVER".localizedNew, for: .normal)
                self.lblWalletBalance.text = "TTL_WALLET_BALANCE_DRIVER".localizedNew
                
            }
            initView()
            self.view.layoutIfNeeded()
            DispatchQueue.main.async {
                SMLoading.hideLoadingPage()
                
            }

            break
        default :
            break
        }
    }
    func initTableView() {
        
    }
    
    func getMerchantData() {
        SMLoading.showLoadingPage(viewcontroller: self)
        SMMerchant.getAllMerchantsFromServer(SMUserManager.accountId, { (response) in
            
            self.userMerchants = SMMerchant.getAllMerchantsFromDB()
            self.initView()
        }) { (error) in
            //
        }
    }
    
    
    
    @objc func showSetting(){
        
        let walletSettingPage : IGWalletSettingTableViewController? = (storyboard?.instantiateViewController(withIdentifier: "walletSettingPage") as! IGWalletSettingTableViewController)
        self.navigationController!.pushViewController(walletSettingPage!, animated: true)
        
    }
    
    @objc func showReceivers(){
        bussinessArray.removeAll()
        Merchantitems.removeAll()
        Taxyitems.removeAll()
        otheritems.removeAll()
        var menuView: DropdownMenu?
        menuView?.layer.cornerRadius = 15.0
        menuView?.clipsToBounds = true

        
        for i in 0..<userMerchants!.count {
            bussinessArray.append(userMerchants![i].businessType ?? 3)
        }
        let tt = userMerchants
        bussinessArray = uniq(source: bussinessArray)
        for ii in userMerchants! {
            if let tmpVal : Int = ii.businessType {
                switch tmpVal {
                case 0 :
                    currentBussinessType = 0
                    let tmpItem = DropdownItem(image: nil, title: "\((ii.name)!) - \((ii.role!).localizedNew)", id: (ii.id!), role: (ii.role!), bType: (ii.businessType!))
                    Merchantitems.append(tmpItem)
                    break
                case 1 :
                    let tmpItem = DropdownItem(image: nil, title: "\((ii.name)!) - \((ii.role!).localizedNew)", id: (ii.id!), role: (ii.role!), bType: (ii.businessType!))
                    otheritems.append(tmpItem)

                    break
                case 2 :
                    let tmpItem = DropdownItem(image: nil, title: "\((ii.name)!) - \((ii.role!).localizedNew)", id: (ii.id!), role: (ii.role!), bType: (ii.businessType!))
                    Taxyitems.append(tmpItem)

                    break
                default :
                    break
                }
            }

        }
        if showSection {
            let test = bussinessArray.count
            let testT = bussinessArray
            switch bussinessArray.count {
            case 1 :
                let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                items = [[item0]]
                menuView = DropdownMenu(navigationController: navigationController!, sections: [section0], selectedIndexPath: selectedIndexPath)
                break
            case 2 :

                if bussinessArray.contains(0) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "store".localizedNew, items: Merchantitems)
                    
                    
                    
                    items = [[item0],Merchantitems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1], selectedIndexPath: selectedIndexPath)
                    
                }
                else if bussinessArray.contains(1) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "other".localizedNew, items: otheritems)
                    
                    
                    
                    items = [[item0],otheritems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1], selectedIndexPath: selectedIndexPath)
                    
                }
                else if bussinessArray.contains(2) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "driver".localizedNew, items: Taxyitems)
                    
                    
                    
                    items = [[item0],Taxyitems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1], selectedIndexPath: selectedIndexPath)
                    
                }
                

                
                break
            case 3 :
                if (bussinessArray.contains(0)) && (bussinessArray.contains(1)) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "store".localizedNew, items: Merchantitems)
                    let section2 = DropdownSection(sectionIdentifier:  "other".localizedNew, items: otheritems)
                    
                    
                    
                    items = [[item0],Merchantitems ,otheritems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1 ,section2], selectedIndexPath: selectedIndexPath)
                    
                }
                
                else if (bussinessArray.contains(0)) && (bussinessArray.contains(2)) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "store".localizedNew, items: Merchantitems)
                    let section2 = DropdownSection(sectionIdentifier:  "driver".localizedNew, items: Taxyitems)
                    
                    
                    
                    items = [[item0],Merchantitems ,Taxyitems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1 ,section2], selectedIndexPath: selectedIndexPath)
                    
                }
                
                else if (bussinessArray.contains(1)) && (bussinessArray.contains(2)) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "other".localizedNew, items: otheritems)
                    let section2 = DropdownSection(sectionIdentifier:  "driver".localizedNew, items: Taxyitems)
                    
                    
                    
                    items = [[item0],otheritems ,Taxyitems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1 ,section2], selectedIndexPath: selectedIndexPath)
                    
                }
                break
            case 4 :
                
                if (bussinessArray.contains(0)) && (bussinessArray.contains(1))  && (bussinessArray.contains(2)) {
                    let item0 = DropdownItem(image: nil, title: "paygearuser".localizedNew, id: SMUserManager.accountId, role: ("paygearuser"), bType: 3)
                    let section0 = DropdownSection(sectionIdentifier:  "", items: [item0])
                    
                    let section1 = DropdownSection(sectionIdentifier:  "store".localizedNew, items: Merchantitems)
                    let section2 = DropdownSection(sectionIdentifier:  "other".localizedNew, items: otheritems)
                    let section3 = DropdownSection(sectionIdentifier:  "driver".localizedNew, items: Taxyitems)

                    
                    
                    items = [[item0],Merchantitems ,otheritems,Taxyitems]
                    menuView = DropdownMenu(navigationController: navigationController!, sections: [section0,section1 ,section2,section3], selectedIndexPath: selectedIndexPath)
                    
                }
                break
            default :
                break
            }
            
        }
        menuView?.textFont = UIFont.igFont(ofSize: 15)
        menuView?.sectionHeaderStyle.font = UIFont.igFont(ofSize: 15)
        
        //menuView?.separatorStyle = .none
        menuView?.zeroInsetSeperatorIndexPaths = [IndexPath(row: 1, section: 0)]
        menuView?.delegate = self
        menuView?.rowHeight = 50
        
        menuView?.showMenu()
    }


    // MARK : - init View elements
    func initNavigationBar(){
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: nil, title: "SETTING_PAGE_WALLET".localizedNew)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }
    @IBAction func btnGoToCashInTap(_ sender: Any) {
        let cashinVC : chargeWalletTableViewController? = (storyboard?.instantiateViewController(withIdentifier: "cashinVC") as! chargeWalletTableViewController)
        cashinVC!.balance = lblCurrency.text!
        cashinVC!.finishDelegate = self
        self.navigationController!.pushViewController(cashinVC!, animated: true)
        
    }
    @IBAction func btnGoToCashOutTap(_ sender: Any) {
        let cashoutVC : chashoutCardTableViewController? = (storyboard?.instantiateViewController(withIdentifier: "cashoutVC") as! chashoutCardTableViewController)
        cashoutVC!.balance = lblCurrency.text!
        cashoutVC!.finishDelegate = self
        self.navigationController!.pushViewController(cashoutVC!, animated: true)
        
    }
    @IBAction func btnQRcodeScan(_ sender: Any) {
        let qrVC: QRMainTabbarController? = (storyboard?.instantiateViewController(withIdentifier: "qrMainTabbar") as! QRMainTabbarController)
        merchantBalance = (lblCurrency.text!).inEnglishNumbersNew()
        
        
        self.navigationController!.pushViewController(qrVC!, animated: true)
        
    }
    @IBAction func btnGoToHistory(_ sender: Any) {
        let historyVC: SMHistoryTableViewController? = (storyboard?.instantiateViewController(withIdentifier: "historytable") as! SMHistoryTableViewController)
        historyVC?.isInStandardHistoPage = true
        self.navigationController!.pushViewController(historyVC!, animated: true)
        
    }
    func callRefreshToken() {
        SMUserManager.refreshToken(delegate: self, onSuccess: { (response) in
            
        }, onFail: { (response) in
            NSLog("%@", "FailedHandler")
        })
    }
    
    func initCardView () {
        
    }
    func finishDefault(isPaygear: Bool? ,isCard : Bool?) {
      

        SMLoading.showLoadingPage(viewcontroller: self)

        if isCard! == false && isPaygear == true {
            if needToUpdate {
                lblCurrency.text = "Updating ...".localizedNew

            }
            else {
                lblCurrency.text = "..."

            }
//                startAnimating()
        }
        else {
            if needToUpdate {
                lblCurrency.text = "Updating ...".localizedNew
                
            }
            else {
                lblCurrency.text = "..."
                
            }        }

        SMCard.getAllCardsFromServer({ cards in
            if cards != nil{
                if (cards as? [SMCard]) != nil{
                    if (cards as! [SMCard]).count > 0 {
//                        self.walletView.dismissPresentedCardView(animated: true)
//                        self.walletHeaderView.alpha = 1.0
                        self.userCards = SMCard.getAllCardsFromDB()
                        self.hasValue = true
                        
                        if self.hasValue  {
                            if (self.userCards?.count)! > 1 {
                                
                                _ = Array((self.userCards?.dropFirst())!)

                                self.stringClubAmountsArray.removeAll()
                                self.stringImgArray.removeAll()
                                self.indexOfCardsWithEmptyBG.removeAll()
                                self.stringCardNumArray.removeAll()
                                self.stringBankCodeArray.removeAll()
                                self.stringBankNameArray.removeAll()
                                self.stringBankLogoArray.removeAll()
                                self.stringCardTypeArray.removeAll()
                                self.stringCardTokenArray.removeAll()
                                self.stringCardisDefaultArray.removeAll()
//                                print(self.userCards)
                                for element in self.userCards! {
                                    if !(element.pan!.contains("پیگیر")) {
                                        
                                        if (element.type) == 1 {
                                            if let back : String = (element.backgroundimage ?? "")  {
                                                let request = WS_methods(delegate: self, failedDialog: true)
                                                if back == "" {
                                                    
                                                    self.stringImgArray.append(back)
                                                    
                                                }
                                                else {
                                                    let str = request.fs_getFileURL(back)
                                                    self.stringImgArray.append(str!)
                                                    
                                                }
                                                
                                            }
                                            if let tmpCardNum : String = (element.pan) {
                                                self.stringCardNumArray.append(tmpCardNum)
                                                
                                            }
                                            if let tmpBankCode : Int64 = (element.bankCode) {
                                                self.stringBankCodeArray.append(tmpBankCode)
                                                
                                            }
                                            if let tmpcardToken : String = (element.token) {
                                                self.stringCardTokenArray.append(tmpcardToken)
                                                
                                            }
                                            if let tmpCardType : Int64 = (element.type) {
                                                self.stringCardTypeArray.append(tmpCardType)
                                                
                                            }
                                            if let tmpIsDefaultState : Bool = (element.isDefault) {
                                                self.stringCardisDefaultArray.append(tmpIsDefaultState)
                                            }
                                            if let tmpIsDefaultAmount : Int64 = ((element.balance ?? 0)) {
                                                self.stringClubAmountsArray.append(tmpIsDefaultAmount)
                                            }
                                            self.getBankInfo()
                                            
                                            
                                        }
                                        else {
                                            if let back : String = (element.backgroundimage ?? "")  {
                                                let request = WS_methods(delegate: self, failedDialog: true)
                                                if back == "" {
                                                    
                                                    self.stringImgArray.insert(back, at: 0)
                                                    
                                                }
                                                else {
                                                    let str = request.fs_getFileURL(back)
                                                    self.stringImgArray.insert(str!, at: 0)
                                                    
                                                }
                                                
                                            }
                                            if let tmpCardNum : String = (element.pan) {
                                                self.stringCardNumArray.insert(tmpCardNum, at: 0)
                                                
                                            }
                                            if let tmpBankCode : Int64 = (element.bankCode) {
                                                self.stringBankCodeArray.insert(tmpBankCode, at: 0)
                                                
                                            }
                                            if let tmpcardToken : String = (element.token) {
                                                self.stringCardTokenArray.insert(tmpcardToken, at: 0)
                                                
                                            }
                                            if let tmpCardType : Int64 = (element.type) {
                                                self.stringCardTypeArray.insert(tmpCardType, at: 0)
                                                
                                            }
                                            if let tmpIsDefaultState : Bool = (element.isDefault) {
                                                self.stringCardisDefaultArray.insert(tmpIsDefaultState, at: 0)
                                            }
                                            if let tmpIsDefaultAmount : Int64 = ((element.balance ?? 0)) {
                                                self.stringClubAmountsArray.insert(tmpIsDefaultAmount, at: 0)
                                            }
                                            self.getBankInfo()
                                            
                                            
                                        }
                        

                                    }
                                    
                                }
                                
                                self.plusValue = ((self.userCards?.count)! - 2 ) * 100
                                
                                
                            }
                            else {
                                self.plusValue = 0
                            }
                        }
                        self.cardCollectionView.reloadData()
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                        if   isPaygear!{
                            self.preparePayGearCard()
                        }
                        if isCard!{
                            
                        }
                        

                    }
                }
            }
            needToUpdate = true
        }, onFailed: {err in
//            SMLoading.showToast(viewcontroller: self, text: "serverDown".localized)
        })
    }
    
    func preparePayGearCard(){

        if let cards = userCards {
            for card in cards {
                
                if card.type == 1 && card.pan!.contains("پیگیر"){
                    
                    lblCurrency.text = String.init(describing: card.balance ?? 0).inRialFormat()
                    merchantBalance = (lblCurrency.text!).inEnglishNumbersNew()

                    if (lblCurrency.text)?.inEnglishNumbersNew() == "0" {
                        btnCashout.isEnabled = false
                        btnCashout.backgroundColor = .iGapGray()
                        btnCharge.backgroundColor = .iGapGreen()
                        btnCashout.isUserInteractionEnabled = false
                    }
                    else {
                        btnCashout.isEnabled = true
                        btnCashout.backgroundColor = .iGapGreen()
                        btnCharge.backgroundColor = .iGapGreen()
                        btnCashout.isUserInteractionEnabled = true

                    }

                    SMUserManager.payGearToken = card.token
                    SMUserManager.isProtected = card.protected
                    SMUserManager.userBalance = card.balance

                    if ((card.balance ?? 0) - (card.cashablebalance ?? 0)) == 0 {

                        
                    }
                    else{

                    }
                }
            }
        }
    }
    //Mark : UITableView
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.item == 2 {
            if shouldShowHisto {
                return 0
            }
            else {
                if !hasValue {
                    return CGFloat(1 * (defaultHeightSize))
                }
                else {
//                    let tmpMin : Int! = ((self.userCards?.count)! - 1)  * (100)
//                    return CGFloat((CGFloat((self.userCards?.count)!) * CGFloat(defaultHeightSize) - (CGFloat((self.userCards?.count)! - tmpMin))))
                    return CGFloat(((self.userCards?.count)!) * (defaultCelltSize / 2))
                    
                }
            }
            
        }
        else if indexPath.item == 0 {
            return 331
        }
        else if indexPath.item == 1 {
            if shouldShowHisto {
                return 0

            }
            else {
                return 57

            }
        }
        else if indexPath.item == 3 {
            if shouldShowHisto {
            return 57
            }
            else {
                return 0

            }
        }
        else if indexPath.item == 4 {
            if shouldShowHisto {
                return 331
            }
            else {
                return 0

            }
            
        }
        else {
            return 57
        }
    }

    //Mark : UIcollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !hasValue {
            return 0
        }
        else {
            if (self.userCards?.count)! > 1 {
            return ((userCards?.count)! - 1)
            }
            else {
                return 0
            }
        }
     
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        SMLoading.showLoadingPage(viewcontroller: self)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardsCollectionViewCell", for: indexPath) as! CardsCollectionViewCell
        if hasValue {
            if (self.stringImgArray[indexPath.item]) == "" {
                
                cell.imgBackground.image = UIImage(named:"default_card_pattern")
                }
                else {
                
                cell.imgBackground.downloadedFrom(link: self.stringImgArray[indexPath.item] , cashable: true, contentMode: .scaleToFill, completion: {_ in
                })
                }
            cell.cellType = self.stringCardTypeArray[indexPath.item]
            let tmpType = self.stringCardTypeArray[indexPath.item]
            if cell.cellType == 1 {
                cell.lblBankName.text = ""
                cell.lblCardNum.text = self.stringCardNumArray[indexPath.item].inLocalizedLanguage()
                let cardNum = (self.stringCardNumArray[indexPath.item])
            }
            else {
                cell.lblCardNum.text = self.stringCardNumArray[indexPath.item].addSepratorforCardNum().inLocalizedLanguage()

                let cardNum = (self.stringCardNumArray[indexPath.item])
                let trimmedString: String = (cardNum as NSString).substring(from: max(cardNum.length-4,0)).inLocalizedLanguage()
                if SMLangUtil.loadLanguage() == "fa" {
                    cell.lblBankName.text = self.stringBankNameArray[indexPath.item] + " - " + trimmedString + "****"

                }
                else {
                    cell.lblBankName.text = self.stringBankNameArray[indexPath.item] + " - " + "****" + trimmedString

                }
                
                }
            
            cell.imgBankLogo.image = UIImage(named: self.stringBankLogoArray[indexPath.item])
            if (cell.lblBankName.text?.contains("پاس"))! {
                cell.lblCardNum.textColor = UIColor.iGapGold()
                cell.lblBankName.textColor = UIColor.iGapGold()
            }
            else {
                cell.lblCardNum.textColor = UIColor.black
                cell.lblBankName.textColor = UIColor.black
            }
        }
        DispatchQueue.main.async {
            SMLoading.hideLoadingPage()

        }
        return cell
        
    }
    func getBankInfo() {
        self.stringBankNameArray.removeAll()
        self.stringBankLogoArray.removeAll()
        for element in self.stringBankCodeArray {
            bank.setBankInfo(code: element)
            stringBankLogoArray.append(bank.logoRes!)
            if element == 69 {
                
                stringBankNameArray.append(bank.nameFA!)

            }
            else {
                stringBankNameArray.append(bank.nameFA!)
            }
            
        }
    }
    
    func initCollectionView() {
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))

        self.cardCollectionView.addGestureRecognizer(lpgr)
        layout = cardCollectionView.collectionViewLayout as! UICollectionViewFlowLayout

        layout.minimumInteritemSpacing = 10
        
        let heideghtSize = ((defaultWidthSize) / 2 )
        layout.minimumLineSpacing =  CGFloat((Double(heideghtSize) / 1.8) * -1)

        let cellSize = CGSize(width:((UIScreen.main.bounds.width) - 40) , height: CGFloat(heideghtSize))
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)

        layout.itemSize = cellSize
        print(cellSize.height)

        defaultCelltSize = Int(cellSize.height)
        cardCollectionView.collectionViewLayout = layout
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardDetailVC : IGWalletCardDetailTableViewController? = (storyboard?.instantiateViewController(withIdentifier: "IGWalletCardDetail") as! IGWalletCardDetailTableViewController)
      
        cardDetailVC!.logoString = self.stringBankLogoArray[indexPath.item]
        cardDetailVC!.urlBack = self.stringImgArray[indexPath.item]
        if (self.stringCardTypeArray[indexPath.item]) == 1 {
            cardDetailVC?.cardNum = self.stringCardNumArray[indexPath.item]

        }
        else {
            cardDetailVC?.cardNum = self.stringCardNumArray[indexPath.item].addSepratorforCardNum()

        }
        cardDetailVC?.cardToken = self.stringCardTokenArray[indexPath.item]
        cardDetailVC?.cardDefault = self.stringCardisDefaultArray[indexPath.item]
        cardDetailVC?.cardType = self.stringCardTypeArray[indexPath.item]
        cardDetailVC?.amount = String((self.stringClubAmountsArray[indexPath.item]))

        let tmp = (self.stringClubAmountsArray)
        let topIndex = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: topIndex, at: .top, animated: true)
        self.navigationController!.pushViewController(cardDetailVC!, animated: true)
    }
    
    //MARK:- MERCHANTS SERVICES
    func getMerChantCards(){
        SMLoading.showLoadingPage(viewcontroller: self)
        lblCurrency.text = "Updating ...".localizedNew

        DispatchQueue.main.async {
            SMCard.getMerchatnCardsFromServer(accountId: merchantID, { (value) in
                if let card = value {
                    self.merchantCard = card as? SMCard
                    self.prepareMerChantCard()
                }
            }, onFailed: { (value) in
                // think about it
                DispatchQueue.main.async {
                    SMLoading.hideLoadingPage()
                    
                }            })
        }
        DispatchQueue.main.async {
            SMLoading.hideLoadingPage()
            
        }
        
    }
    
    func prepareMerChantCard() {
        
        if let card = merchantCard {
            if card.type == 1 {
//                amountLbl.isHidden = false
                lblCurrency.text = String.init(describing: card.balance ?? 0).inRialFormat()
                let tmp = lblCurrency.text
                if tmp?.inEnglishNumbersNew() == "0" {
                    btnCashout.isEnabled = false
                    btnCashout.backgroundColor = .iGapGray()
                    btnCharge.backgroundColor = .iGapGreen()

                    btnCashout.isUserInteractionEnabled = false
                }
                else {
                    btnCashout.isEnabled = true
                    btnCashout.backgroundColor = .iGapGreen()
                    btnCharge.backgroundColor = .iGapGreen()
                    btnCashout.isUserInteractionEnabled = true


                }
                NotificationCenter.default.post(name: Notification.Name(SMConstants.notificationHistoryMerchantUpdate), object: nil,
                                                userInfo: ["id": merchantID])

            }
            SMLoading.hideLoadingPage()

        }
    }

}

extension packetTableViewController: DropdownMenuDelegate {
    func dropdownMenu(_ dropdownMenu: DropdownMenu, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        print(indexPath.row)

        switch indexPath.section {
        case 0 :
            shouldShowHisto = false
            currentBussinessType = 3
            merchantID = SMUserManager.accountId
            currentRole = "paygearuser"
            self.tableView.beginUpdates()
            setupUI()
            finishDefault(isPaygear: true, isCard: false)
            isMerchant = false

            self.tableView.endUpdates()
            break
        case 1 :
            
            
            shouldShowHisto = true
            self.tableView.beginUpdates()
            currentBussinessType = items[indexPath.section][indexPath.row].bType ?? 0
            merchantID = items[indexPath.section][indexPath.row].id

            currentRole = items[indexPath.section][indexPath.row].role
            setupUI()
            getMerChantCards()
            isMerchant = true

            self.tableView.endUpdates()

            break
        case 2 :
            shouldShowHisto = true
            self.tableView.beginUpdates()
            merchantID = items[indexPath.section][indexPath.row].id
            currentBussinessType = items[indexPath.section][indexPath.row].bType ?? 2
            currentRole = items[indexPath.section][indexPath.row].role
            setupUI()
            getMerChantCards()
            isMerchant = true
            
            self.tableView.endUpdates()
            
            break
        case 3 :
            shouldShowHisto = true
            self.tableView.beginUpdates()
            merchantID = items[indexPath.section][indexPath.row].id
            currentBussinessType = items[indexPath.section][indexPath.row].bType ?? 2
            currentRole = items[indexPath.section][indexPath.row].role
            setupUI()
            getMerChantCards()
            isMerchant = true
            
            self.tableView.endUpdates()
            
            break
        default :
            break
        }
        print(merchantID)
        print("||||||||INDEX2")

        
    }
    
}
func uniq<S : Sequence, T : Hashable>(source: S) -> [T] where S.Iterator.Element == T {
    var buffer = [T]()
    var added = Set<T>()
    for elem in source {
        if !added.contains(elem) {
            buffer.append(elem)
            added.insert(elem)
        }
    }
    return buffer
}

