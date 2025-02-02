/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import Foundation
import UIKit
import IGProtoBuff
import SwiftProtobuf
import RealmSwift
import RxSwift
import WebRTC
import FirebaseInstanceID
import maincore
import SwiftEventBus
import RxCocoa
import Files

class IGAppManager: NSObject {
    static let sharedManager = IGAppManager()
    internal static var iceServersStatic: [RTCIceServer] = []
    
    enum ConnectionStatus {
        case waitingForNetwork
        case connecting
        case connected
        case iGap // login state
    }
    var realm = try! Realm()
    var connectionStatus: BehaviorRelay<ConnectionStatus>
    static var connectionStatusStatic: IGAppManager.ConnectionStatus?
    var isUserLoggedIn: BehaviorRelay<Bool>
    var isTryingToLoginUser: Bool = false
    var currentMessagesNotificationToekn: NotificationToken?
    var showFetchingRoomList: Bool = false // this varibale used for check and show Fetching Room view if needed, at navigation bar after change tab and return to room list tab again
    var allowFetchRoomList: Bool = false
    var fetchRoomListOffset: Int = 0
    
    private var _loginToken: String?
    private var _username: String?
    private var _userID: Int64?
    private var _authorHash: String?
    private var _nickname: String?
    private var _mapEnable: Bool = false
    private var _mplActive: Bool = false
    private var _md5Hex: String?
    private var _walletRegistered: Bool = false
    private var _walletActive: Bool = false
    private var _AccessToken: String!
    private var _SymmetricKey: Data!
    
    var webSocketUrl = "wss://secure.igap.net/hybrid/"
    var debugMode = false
    var debugger: IGDebugger = .Firebase
    var timeOut = 10
    var maxFileSize: Int64 = 100000000
    var captionMaxLength = 1024
    var messageMaxLength = 4096
    var groupMemberLimit = 10000
    var channelMemberLimit = 10000
    var UploadDownloadMethod: RequestMethod = .Rest
    var blockMethod: RequestMethod = .Socket

    public let LOAD_ROOM_LIMIT = 50
    public let APP_ID = 3
    
    private override init() {
        connectionStatus = BehaviorRelay(value: .waitingForNetwork)
        isUserLoggedIn   = BehaviorRelay(value: false)
        super.init()
        
        /***** detect contact change *****/
        NotificationCenter.default.addObserver(self, selector: #selector(addressBookDidChange(_:)), name: NSNotification.Name.CNContactStoreDidChange, object: nil)
        createAppDirectories()
    }
    
   @objc func addressBookDidChange(_ notification: UITapGestureRecognizer) {
        if !IGContactManager.syncedPhoneBookContact {
            IGContactManager.syncedPhoneBookContact = true
            IGContactManager.sharedManager.manageContact()
        }
    }
    
    /***** make app directories for save downloaded and uploaded files *****/
    public func createAppDirectories(){
        do {
            /**** main directories ***/
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR + IGGlobal.IMAGE_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR + IGGlobal.VIDEO_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR + IGGlobal.AUDIO_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR + IGGlobal.VOICE_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR + IGGlobal.GIF_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.APP_DIR + IGGlobal.FILE_DIR, withIntermediateDirectories: true, attributes: nil)
            /**** cache directories ***/
            try FileManager.default.createDirectory(atPath: IGGlobal.CACHE_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.CACHE_DIR + IGGlobal.THUMB_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.CACHE_DIR + IGGlobal.BACKGROUND_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.CACHE_DIR + IGGlobal.AVATAR_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: IGGlobal.CACHE_DIR + IGGlobal.STICKER_DIR, withIntermediateDirectories: true, attributes: nil)
            /**** temporary directories ***/
            try FileManager.default.createDirectory(atPath: IGGlobal.TEMP_DIR, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Unable to create directory \(error.debugDescription)")
        }
    }
    
    public func setNetworkConnectionStatus(_ status: ConnectionStatus) {
        self.connectionStatus.accept(status)
    }
    
    public func setUserUpdateStatus(status: IGRegisteredUser.IGLastSeenStatus) {
            IGUserUpdateStatusRequest.Generator.generate(userStatus: status).success({ (protoResponse) in
                DispatchQueue.main.async {
                    switch protoResponse {
                    case let userUpdateStatus as IGPUserUpdateStatusResponse:
                        IGUserUpdateStatusRequest.Handler.interpret(response: userUpdateStatus)
                    default:
                        break
                    }
                }
            }).error({ (errorCode, waitTime) in
                switch errorCode {
                    
                default:
                    break
                }
            }).send()
        
    }

    public func clearDataOnLogout() {
        _loginToken = nil
        _username = nil
        _userID = nil
        _authorHash = nil
        _nickname = nil
        _mapEnable = false
        
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let sessionInfo = IGDatabaseManager.shared.realm.objects(IGSessionInfo.self).first {
                    sessionInfo.loginToken = nil
                }
                
                IGDatabaseManager.shared.realm.deleteAll()
            }
            //IGDatabaseManager.shared.emptyQueue()
        }
        
        IGRequestManager.sharedManager.userDidLogout()
        IGHelperPreferences.shared.removeAllPreferences()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.deleteToken()
        appDelegate.refreshFCMToken()

    }
    
    public func bundleShortVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "0.0.0"
    }
    
    public func bundleVersion() -> Int {
        if let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            if let buildV = Int(buildVersion) {
                 return buildV
            } else {
               return 1
            }
        } else {
            return 1
        }
    }
    
    public func isUserPreviouslyLoggedIn() -> Bool {
        if let sessionInfo = realm.objects(IGSessionInfo.self).first {
            if sessionInfo.loginToken != nil {
                fillUserInfo(sessionInfo: sessionInfo)
                return true
            }
        }
        return false
    }
    
    private func fillUserInfo(sessionInfo: IGSessionInfo? = nil){
        
        var info : IGSessionInfo?
        if sessionInfo == nil {
            let realm = try! Realm()
            info = realm.objects(IGSessionInfo.self).first
        } else {
            info = sessionInfo
        }
        
        if info != nil {
            _loginToken = info?.loginToken
            _username = info?.username
            _userID = info?.userID
            _nickname = info?.nickname
            _authorHash = info?.authorHash
        }
    }
    
    /**
     * reset app value after than connection lost
     **/
    public func resetApp(){
        IGDownloadManager.sharedManager.pauseAllDownloads()
        IGUploadManager.sharedManager.pauseAllUploads()
        IGContactManager.importedContact = false // for allow user that import contact list after than logged in again
        IGRecentsTableViewController.needGetInfo = true
        IGDashboardViewController.needGetFirstPage = true
        allowFetchRoomList = true
        showFetchingRoomList = false
        fetchRoomListOffset = 0
        
        if let delegate = RTCClient.getInstance()?.callStateDelegate {
            delegate.onStateChange(state: RTCClientConnectionState.Unavailable)
        }
    }
    
    public func setUserLoginSuccessful() {
        isUserLoggedIn.accept(true)
        SwiftEventBus.postToMainThread(EventBusManager.login)
    }
    
    public func getSignalingConfiguration(force:Bool = false){
        let realm = try! Realm()
        let signalingConfig = realm.objects(IGSignaling.self).first
        if signalingConfig == nil || force {
            IGSignalingGetConfigurationRequest.Generator.generate().success({ (protoResponse) in
                DispatchQueue.main.async {
                    switch protoResponse {
                    case let configurationResponse as IGPSignalingGetConfigurationResponse:
                        IGSignalingGetConfigurationRequest.Handler.interpret(response: configurationResponse)
                    default:
                        break
                    }
                }
            }).error ({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    self.getSignalingConfiguration()
                    break
                default:
                    break
                }
            }).send()
        }
    }
    
    public func isUserLoggiedIn() -> Bool {
        return isUserLoggedIn.value
    }
    
    public func save(token: String?) {
        _loginToken = token
        
        if _username == nil || _username == "" {
            _username = AppDelegate.usernameRegister
        }
        
        if _userID == nil || _userID == 0 {
            _userID = AppDelegate.userIdRegister
        }
        
        if _authorHash == nil || _authorHash == "" {
            _authorHash = AppDelegate.authorHashRegister
        }
        
        if let sessionInto = realm.objects(IGSessionInfo.self).first {
            try! realm.write {
                sessionInto.loginToken = token
                sessionInto.username = _username
                sessionInto.userID = _userID!
                sessionInto.authorHash = _authorHash
            }
        } else {
            let sessionInto = IGSessionInfo()
            sessionInto.loginToken = token
            sessionInto.username = _username
            sessionInto.userID = _userID!
            sessionInto.authorHash = _authorHash
            try! realm.write {
                realm.add(sessionInto, update: .modified)
            }
        }
    }
    
    public func save(username: String?) {
        AppDelegate.usernameRegister = username
        _username = username
        if let sessionInto = realm.objects(IGSessionInfo.self).first {
            try! realm.write {
                sessionInto.username = username
            }
        } else {
            let sessionInto = IGSessionInfo()
            sessionInto.username = username
            try! realm.write {
                realm.add(sessionInto, update: .modified)
            }
        }
    }
    
    public func save(userID: Int64?) {
        AppDelegate.userIdRegister = userID
        _userID = userID
        var userId: Int64 = -1
        if userID != nil {
            userId = userID!
        }
        if let sessionInto = realm.objects(IGSessionInfo.self).first {
            try! realm.write {
                sessionInto.userID = userId
            }
        } else {
            let sessionInto = IGSessionInfo()
            sessionInto.userID = userId
            try! realm.write {
                realm.add(sessionInto, update: .modified)
            }
        }
    }
    
    public func save(authorHash: String?) {
        AppDelegate.authorHashRegister = authorHash
        _authorHash = authorHash
        if let sessionInto = realm.objects(IGSessionInfo.self).first {
            try! realm.write {
                sessionInto.authorHash = authorHash
            }
        } else {
            let sessionInto = IGSessionInfo()
            sessionInto.authorHash = authorHash
            try! realm.write {
                realm.add(sessionInto, update: .modified)
            }
        }
    }
    
    public func save(nickname: String) {
        _nickname = nickname
    }
    
    public func loginToken() -> String? {
        return _loginToken
    }
    
    public func getAccessToken() -> String? {
        if let session = IGDatabaseManager.shared.realm.objects(IGSessionInfo.self).first {
            return session.accessToken
        } else {
            return nil
        }
    }
    
    public func username() -> String? {
        return _username
    }
    
    public func userID() -> Int64? {
        return _userID
    }
    
    public func authorHash() -> String? {
        return _authorHash
    }
    
    public func nickname() -> String? {
        return _nickname
    }
    
    public func mapEnable() -> Bool {
        return _mapEnable
    }
    
    public func setMapEnable(enable: Bool) {
        _mapEnable = enable
    }
    
    public func mplActive() -> Bool {
        return _mplActive
    }
    public func md5Hex() -> String {
        return _md5Hex ?? ""
    }
    
    public func setWalletRegistered(enable: Bool) {
        _walletRegistered = enable
    }
    public func walletRegistered() -> Bool {
        return _walletRegistered
    }
    
    public func setMplActive(enable: Bool) {
        _mplActive = enable
    }
    public func setMd5Hex(md5Hex: String) {
        _md5Hex = md5Hex
    }
    
    public func walletActive() -> Bool {
        return _walletActive
    }
    
    public func setWalletActive(enable: Bool) {
        _walletActive = enable
    }
    public func symmetricKey() -> Data {
        return _SymmetricKey
    }
    public func setSymmetricKey(key: Data) {
        _SymmetricKey = key
    }
    public func setAccessToken(accessToken: String, completion: (() -> Void)? = nil) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let session = IGDatabaseManager.shared.realm.objects(IGSessionInfo.self).first {
                    session.accessToken = accessToken
                }
            }
            IGApiBase.sharedApiBase.refreshHeader()
            if completion != nil {
                completion!()
            }
        }
    }
    
    public func login() {
        if !self.isTryingToLoginUser {
            self.isTryingToLoginUser = true
            
            if _loginToken == nil {
                fillUserInfo()
            }
            
            if _loginToken != nil {
                IGUserLoginRequest.Generator.generate(token: _loginToken!).success({ (responseProto) in
                    DispatchQueue.main.async {
                        self.isTryingToLoginUser = false
                        switch responseProto {
                        case _ as IGPUserLoginResponse:
                            IGUserLoginRequest.Handler.intrepret(response: (responseProto as? IGPUserLoginResponse)!)
                            self.setUserUpdateStatus(status: .online)
                            self.getSignalingConfiguration(force: true)
                            self.getGeoRegisterStatus()
                            break
                        default:
                            break
                        }
                    }
                }).error({ (errorCode, waitTime) in
                    self.isTryingToLoginUser = false
                    switch errorCode {
                    case .timeout:
                        IGWebSocketManager.sharedManager.closeConnection()//self.login()
                        break
                    case .floodRequest:
                        IGWebSocketManager.sharedManager.closeConnection()
                        break
                    case .userLoginFailed, .userLoginFailedOne, .userLoginFailedTwo, .userLoginFailedThree, .userLoginFaieldUserIsBlocked:
                        DispatchQueue.main.async {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.showLoginFaieldAlert(title: "Login Failed")
                        }
                    default:
                        break
                    }
                }).send()
            } else {
                DispatchQueue.main.async {
                    self.isTryingToLoginUser = false
                }
            }
        }
    }
    
    public func getGeoRegisterStatus(){
        IGGeoGetRegisterStatus.Generator.generate().success({ (responseProto) in
            DispatchQueue.main.async {
                if let geoStatus = responseProto as? IGPGeoGetRegisterStatusResponse {
                    self._mapEnable = geoStatus.igpEnable
                }
            }
        }).error({ (errorCode, waitTime) in
            switch errorCode {
            case .timeout:
                self.getGeoRegisterStatus()
            default:
                break
            }
        }).send()
    }
    
    var mobileBankAccessToken = ""
    
}
