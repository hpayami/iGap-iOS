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
import RealmSwift
import IGProtoBuff
import RxSwift
import Gifu
import MapKit
import SwiftEventBus
import AsyncDisplayKit
import Alamofire

public var currentSize : Int!
public var currentIndexOfImage : Int!
public var sizesArray = [Int?]()
public var isAvatar = true

class IGSettingTableViewController: BaseTableViewController, CLLocationManagerDelegate {
    var tmpH : HTTPHeaders = [
        "userid": "176264689987306100"
    ]
    var req : DataStreamRequest!

    @IBOutlet weak var switchInAppBrowser: UISwitch!
    
    @IBOutlet  var iconArray: [UILabel]!
    @IBOutlet weak var lblNotificationSounds: UILabel!
    @IBOutlet weak var lblPrivacyPolicy: UILabel!
    @IBOutlet weak var lblDataStorage: UILabel!
    @IBOutlet weak var lblChatSettings: UILabel!
    @IBOutlet weak var lblLogOut: UILabel!
    @IBOutlet weak var lblChangeLang: UILabel!
    var userInDb : IGRegisteredUser!
    var imagePicker = UIImagePickerController()
    let locationManager = CLLocationManager()
    let borderName = CALayer()
    let width = CGFloat(0.5)
    var shareContent = NSString()
    var user : IGRegisteredUser?
    var avatars: [IGAvatar] = []
    var deleteView: IGTappableView?
    var userAvatar: IGAvatar?
    var notificationToken: NotificationToken?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDetails()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.tableView.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        
        tableView.tableFooterView = UIView()
            SwiftEventBus.onMainThread(self, name: "initTheme") { [weak self] result in
                self?.initTheme()
            }
            initTheme()
        }
        private func initTheme() {
            lblLogOut.textColor = ThemeManager.currentTheme.LabelColor
            lblChangeLang.textColor = ThemeManager.currentTheme.LabelColor
            lblDataStorage.textColor = ThemeManager.currentTheme.LabelColor
            lblChatSettings.textColor = ThemeManager.currentTheme.LabelColor
            lblPrivacyPolicy.textColor = ThemeManager.currentTheme.LabelColor
            lblNotificationSounds.textColor = ThemeManager.currentTheme.LabelColor
            self.tableView.reloadData()
            for icon in iconArray {
                icon.textColor = ThemeManager.currentTheme.LabelColor
            }
            self.tableView.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
            
        }

    func initDetails() {
        
        self.clearsSelectionOnViewWillAppear = true
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: "", title: IGStringsManager.Settings.rawValue.localized, iGapFont: true)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self

        // navigationItem.setChatListsNavigationItems()
        navigationItem.rightViewContainer?.addAction { [weak self] in
            self?.showMoreActionSheet()
        }
    }
    
    
    func initChangeLanguage() {
        lblChangeLang.text = IGStringsManager.ChangeLang.rawValue.localized
        lblPrivacyPolicy.text = IGStringsManager.PrivacyAndSecurity.rawValue.localized
        lblNotificationSounds.text = IGStringsManager.NotificationAndSound.rawValue.localized
        lblDataStorage.text = IGStringsManager.DataStorage.rawValue.localized
        lblChatSettings.text = IGStringsManager.ChatSettings.rawValue.localized
        lblLogOut.text = IGStringsManager.Logout.rawValue.localized
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.isUserInteractionEnabled = true
        // requestToGetAvatarList()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        initChangeLanguage()
        self.tableView.isUserInteractionEnabled = true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tableView.isUserInteractionEnabled = true
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    deinit {
        print("Deinit IGSettingTableViewController")
    }
    
    var lastIndex: Array<Any>.Index?
    var currentAvatarId: Int64?
    var timer = Timer()
    open private(set) var deleteToolbar: UIToolbar!
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            return 2
        default:
            return 0
        }
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = ThemeManager.currentTheme.TableViewCellColor

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            let rowIndex = indexPath.row
            
            if rowIndex == 0 {
                self.tableView.isUserInteractionEnabled = false
                
                performSegue(withIdentifier: "GoToNotificationSettingsPage", sender: self)
                
            } else if rowIndex == 1 {
                self.tableView.isUserInteractionEnabled = false
                performSegue(withIdentifier: "GoToPrivacyAndPolicySettingsPage", sender: self)
            } else if rowIndex == 2 {
                self.tableView.isUserInteractionEnabled = false
                performSegue(withIdentifier: "GoToDataAndStorage", sender: self)
            }
            else if rowIndex == 3 {
                self.tableView.isUserInteractionEnabled = false
                performSegue(withIdentifier: "GoToChatSettings", sender: self)
                
            }
        } else  {
            if indexPath.row == 0 {
                self.tableView.isUserInteractionEnabled = false
                performSegue(withIdentifier: "showChangeLanguagePage", sender: self)
            }
            else {
//                showLogoutActionSheet()
                
                let imageData = NSMutableData() //or var messageData : NSMutableData = NSMutableData()

//                req = AF.streamRequest("http://192.168.8.15:4001/v1.0/download/fa723fa4-9446-48e8-993c-c59011fc7aeb",method: .get,headers: self.getHeader())
                req = AF.streamRequest("http://192.168.10.31:3007/v1.0/download/vfvf",method: .get,headers: self.getHeader())

                req.responseStream { stream in
                    switch stream.event {
                    case let .stream(result):
                        switch result {
                        case let .success(data):
                            print("+_+_+_+_+_+_+_+_+_+_+_+")
                            print((data))
//                            imageData.append(data)
//                            try? IGFilesManager().save(fileNamed: "tmpImageWolf", data: data)
                            (IGSecurityManager.sharedManager.TEMPdecrypt(encryptedData: data))
                            print("+_+_+_+_+_+_+_+_+_+_+_+")
                        case let .failure(error) :
                            print("+_+_+_+_+_+_+_+_+_+_+_+")
                            print(error)
                            print("+_+_+_+_+_+_+_+_+_+_+_+")

                        }
                    case let .complete(completion):
                        print("-0-0-0-0-0-0-0-0")
                        print(completion.response)
                        print("-0-0-0-0-0-0-0-0")
                        print((IGSecurityManager.sharedManager.TEMPdecrypt(encryptedData: imageData as Data)))

                        let alert = UIAlertController(title: "Title", message: "Message", preferredStyle: .alert)

                        let action = UIAlertAction(title: "OK", style: .default, handler: nil)

                        let imgTitle = UIImage(data: (IGSecurityManager.sharedManager.TEMPdecrypt(encryptedData: imageData as Data)))
                        let imgViewTitle = UIImageView(frame: CGRect(x: 10, y: 10, width: 200, height: 200))
                        imgViewTitle.image = imgTitle

                        alert.view.addSubview(imgViewTitle)
                        alert.addAction(action)

                        self.present(alert, animated: true, completion: nil)
//
//
                    }
                }
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
    public func getHeader() -> HTTPHeaders {
        if IGApiBase.httpHeaders == nil {
            guard let token = IGAppManager.sharedManager.getAccessToken() else { return ["Authorization": ""] }
            let authorization = "Bearer " + token
//            let contentType = "application/json"
            IGApiBase.httpHeaders = ["Authorization": authorization]
        }
        return IGApiBase.httpHeaders
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        return tableView.sectionHeaderHeight
    }
    
    //MARK: - DEVELOPMENT funcs

    private func showLogoutActionSheet(){
        let logoutConfirmAlertView = UIAlertController(title: IGStringsManager.SureToLogout.rawValue.localized , message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        let logoutAction = UIAlertAction(title: IGStringsManager.Logout.rawValue.localized , style:.default , handler: { (alert: UIAlertAction) -> Void in
            IGUserSessionLogoutRequest.sendRequest()
        })
        
        let cancelAction = UIAlertAction(title: IGStringsManager.GlobalCancel.rawValue.localized , style:.cancel , handler: nil)
        logoutConfirmAlertView.addAction(logoutAction)
        logoutConfirmAlertView.addAction(cancelAction)
        let alertActions = logoutConfirmAlertView.actions
        for action in alertActions {
            if action.title == IGStringsManager.Logout.rawValue.localized {
                let logoutColor = UIColor.red
                action.setValue(logoutColor, forKey: "titleTextColor")
            }
        }
        logoutConfirmAlertView.view.tintColor = UIColor.organizationalColor()
        if let popoverController = logoutConfirmAlertView.popoverPresentationController {
            popoverController.sourceView = self.tableView
            popoverController.sourceRect = CGRect(x: self.tableView.frame.midX-self.tableView.frame.midX/2, y: self.tableView.frame.midX-self.tableView.frame.midX/2, width: self.tableView.frame.midX, height: self.tableView.frame.midY)
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        }
        present(logoutConfirmAlertView, animated: true, completion: nil)
    }
    //Delete Account alert controller
    
    private func showMoreActionSheet(){
        let DeleteAccountAlertView = UIAlertController(title: nil , message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        let logoutAction = UIAlertAction(title: IGStringsManager.DeleteAccount.rawValue.localized , style:.default , handler: {
            (alert: UIAlertAction) -> Void in
//                self.logoutProcess()//logout process
                self.deleteAccountProcess()
            
        })
        let cancelAction = UIAlertAction(title: IGStringsManager.GlobalCancel.rawValue.localized , style:.cancel , handler: {
            (alert: UIAlertAction) -> Void in
        })
        DeleteAccountAlertView.addAction(logoutAction)
        DeleteAccountAlertView.addAction(cancelAction)
        let alertActions = DeleteAccountAlertView.actions
        for action in alertActions {
            if action.title == IGStringsManager.DeleteAccount.rawValue.localized {
                let logoutColor = UIColor.red
                action.setValue(logoutColor, forKey: "titleTextColor")
            }
        }
        DeleteAccountAlertView.view.tintColor = UIColor.organizationalColor()
        if let popoverController = DeleteAccountAlertView.popoverPresentationController {
            popoverController.sourceView = self.tableView
            popoverController.sourceRect = CGRect(x: self.tableView.frame.midX-self.tableView.frame.midX/2, y: self.tableView.frame.midX-self.tableView.frame.midX/2, width: self.tableView.frame.midX, height: self.tableView.frame.midY)
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        }
        present(DeleteAccountAlertView, animated: true, completion: nil)
    }
    private func deleteAccountProcess() {

        IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalAttention.rawValue.localized, showIconView: true, showDoneButton: true, showCancelButton: true, message: IGStringsManager.SureToDeleteAccount.rawValue.localized,doneText: IGStringsManager.GlobalOK.rawValue.localized ,cancelText: IGStringsManager.GlobalClose.rawValue.localized,cancel: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }, done: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        })
    }
}

extension IGSettingTableViewController: IGProgressDelegate {
    func downloadUploadIndicatorDidTap(_ indicator: IGProgress) {
        if let attachment = self.userAvatar?.file {
            IGDownloadManager.sharedManager.download(file: attachment, previewType: .originalFile, completion: { (attachment) -> Void in
                
            }, failure: {
                
            })
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
