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
import RealmSwift
import MBProgressHUD
import IGProtoBuff
import MGSwipeTableCell

class IGMemberTableViewController: BaseTableViewController, cellWithMore, UpdateMyRoleObserver {

    var room : IGRoom?
    var filterRole : IGMemberRole = .all
    private var roomId: Int64!
    private var roomType: IGRoom.IGType!
    private var myRole: Int!
    private let FETCH_MEMBER_LIMIT: Int32 = 20
    private var realmNotificationToken: NotificationToken?
    private var realmMembers: Results<IGRealmMember>!
    private var allowFetchMore = false
    public static var updateMyRoleObserver: UpdateMyRoleObserver!

    var searchController : UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = ""
        searchController.searchBar.setValue("CANCEL_BTN".localizedNew, forKey: "cancelButtonText")
        
        let gradient = CAGradientLayer()
        let defaultNavigationBarFrame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.width), height: 64)

        gradient.frame = defaultNavigationBarFrame
        gradient.colors = [UIColor(named: themeColor.navigationFirstColor.rawValue)!.cgColor, UIColor(named: themeColor.navigationSecondColor.rawValue)!.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        
        searchController.searchBar.barTintColor = UIColor(patternImage: IGGlobal.image(fromLayer: gradient))
        searchController.searchBar.backgroundColor = UIColor(patternImage: IGGlobal.image(fromLayer: gradient))
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            if let searchBarCancelButton = searchController.searchBar.value(forKey: "cancelButton") as? UIButton {
                searchBarCancelButton.setTitle("CANCEL_BTN".localizedNew, for: .normal)
                searchBarCancelButton.titleLabel!.font = UIFont.igFont(ofSize: 14,weight: .bold)
                searchBarCancelButton.tintColor = UIColor.white
            }
            
            if let placeHolderInsideSearchField = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeHolderInsideSearchField.textColor = UIColor.white
                placeHolderInsideSearchField.textAlignment = .center
                placeHolderInsideSearchField.text = "SEARCH_PLACEHOLDER".localizedNew
                if let backgroundview = textField.subviews.first {
                    placeHolderInsideSearchField.center = backgroundview.center
                }
                placeHolderInsideSearchField.font = UIFont.igFont(ofSize: 15,weight: .bold)
            }
        }
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IGMemberTableViewController.updateMyRoleObserver = self
        
        self.tableView.bounces = false
        definesPresentationContext = true
        if #available(iOS 11.0, *) {
            self.searchController.searchBar.searchBarStyle = UISearchBar.Style.minimal
            if tableView.tableHeaderView == nil {
                tableView.tableHeaderView = searchController.searchBar
            }
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        roomId = room?.id
        roomType = room?.type
        if roomType == .channel {
            myRole = room?.channelRoom?.role.rawValue
        } else {
            myRole = room?.groupRoom?.role.rawValue
        }
        
        /**
         * don't need to save members and show offline so before load each time, first clear all members and fetch from server
         */
        IGRealmMember.clearMembers {
            DispatchQueue.main.async {
                let predicate = NSPredicate(format: "roomId == %lld", self.roomId) //AND role == %d
                self.realmMembers = IGDatabaseManager.shared.realm.objects(IGRealmMember.self).filter(predicate)
                self.realmNotificationToken = self.realmMembers.observe { (changes: RealmCollectionChange) in
                    switch changes {
                    case .initial:
                        self.tableView.reloadData()
                        break
                    case .update(_, let deletions, let insertions, let modifications):
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .none)
                        self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .none)
                        self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                        self.tableView.endUpdates()
                        break
                    case .error(let err):
                        fatalError("\(err)")
                        break
                    }
                }
                
                self.fetchMemberFromServer()
            }
        }
        
        setNavigationItem()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        initialiseSearchBar()
    }
    
    private func setNavigationItem(){
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: "ADD_BTN".localizedNew, title: "ALLMEMBER".localizedNew)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        navigationItem.rightViewContainer?.addAction {
            self.performSegue(withIdentifier: "showContactToAddMember", sender: self)
        }
    }
    
    //MARK:- Search Bar
    private func initialiseSearchBar() {
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear

            let imageV = textField.leftView as! UIImageView
            imageV.image = nil
            if let backgroundview = textField.subviews.first {
                backgroundview.backgroundColor = UIColor(named: themeColor.searchBarBackGroundColor.rawValue)
                for view in backgroundview.subviews {
                    view.backgroundColor = .clear
                }
                backgroundview.layer.cornerRadius = 10;
                backgroundview.clipsToBounds = true;
                
            }

            if let searchBarCancelButton = searchController.searchBar.value(forKey: "cancelButton") as? UIButton {
                searchBarCancelButton.setTitle("CANCEL_BTN".localizedNew, for: .normal)
                searchBarCancelButton.titleLabel!.font = UIFont.igFont(ofSize: 14,weight: .bold)
                searchBarCancelButton.tintColor = UIColor.white
            }

            if let placeHolderInsideSearchField = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeHolderInsideSearchField.textColor = UIColor.white
                placeHolderInsideSearchField.textAlignment = .center
                placeHolderInsideSearchField.text = "SEARCH_PLACEHOLDER".localizedNew
                if let backgroundview = textField.subviews.first {
                    placeHolderInsideSearchField.center = backgroundview.center
                }
                placeHolderInsideSearchField.font = UIFont.igFont(ofSize: 15,weight: .bold)
            }
        }
    }
    
    private func setSearchBarGradient() {
        let gradient = CAGradientLayer()
        let defaultNavigationBarFrame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.width), height: 64)
        
        gradient.frame = defaultNavigationBarFrame
        gradient.colors = [UIColor(named: themeColor.navigationFirstColor.rawValue)!.cgColor, UIColor(named: themeColor.navigationSecondColor.rawValue)!.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        
        searchController.searchBar.barTintColor = UIColor(patternImage: IGGlobal.image(fromLayer: gradient))
        searchController.searchBar.backgroundColor = UIColor(patternImage: IGGlobal.image(fromLayer: gradient))
    }
    
    //MARK:- Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (realmMembers?.count ?? 0) != 0 {
            self.tableView.restore()
        }
        return realmMembers?.count ?? 0
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? true {
                self.setSearchBarGradient()
            }
        }
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! IGMemberCell
        let member = realmMembers[indexPath.row]
        if member.user == nil {
            fetchUserInfo(userId: member.userId)
        }
        cell.setUser(member, myRole: myRole)
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let room = IGRoom.existRoomInLocal(userId: self.realmMembers[indexPath.row].userId) {
            openChat(room: room)
        } else { // need to create chat
            IGGlobal.prgShow(self.view)
            IGChatGetRoomRequest.Generator.generate(peerId: self.realmMembers[indexPath.row].userId).success({ (protoResponse) in
                DispatchQueue.main.async {
                    IGGlobal.prgHide()
                    if let chatGetRoomResponse = protoResponse as? IGPChatGetRoomResponse {
                        let _ = IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                        let roomU = IGRoom(igpRoom: chatGetRoomResponse.igpRoom)
                        self.openChat(room: roomU)
                    }
                }
            }).error({ (errorCode, waitTime) in
                DispatchQueue.main.async {
                    IGGlobal.prgHide()
                    let alertC = UIAlertController(title: "Error", message: "An error occured trying to create a conversation", preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertC.addAction(cancel)
                    self.present(alertC, animated: true, completion: nil)
                }
            }).send()
        }
    }
    
    
    //MARK:- Popular Methods
    
    /**
     * update states for my user after change state for edit another members
     */
    private func updateMyRoleAndPermissions(roomId: Int64, memberId: Int64, role: Int){
        if IGAppManager.sharedManager.userID() != memberId || roomId != self.roomId {
            return
        }
        myRole = role
        
        DispatchQueue.main.async {
            let navigationItem = self.navigationItem as! IGNavigationItem
            if self.roomType == .channel {
                if role == IGPChannelRoom.IGPRole.admin.rawValue {
                    navigationItem.addNavigationViewItems(rightItemText: "ADD_BTN".localizedNew, title: "ALLMEMBER".localizedNew)
                    navigationItem.rightViewContainer?.addAction {
                        self.performSegue(withIdentifier: "showContactToAddMember", sender: self)
                    }
                } else if role == IGPChannelRoom.IGPRole.moderator.rawValue || role == IGPChannelRoom.IGPRole.member.rawValue {
                    let alertC = UIAlertController(title: "HINT".localizedNew, message: "CHANGED_ROLE_HINT".localizedNew, preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler:  {  action in
                        self.navigationController?.popViewController(animated: true)
                    })
                    alertC.addAction(cancel)
                    UIApplication.topViewController()!.present(alertC, animated: true, completion: nil)
                }
            } else if self.roomType == .group {
                navigationItem.addNavigationViewItems(rightItemText: "ADD_BTN".localizedNew, title: "ALLMEMBER".localizedNew)
                navigationItem.rightViewContainer?.addAction {
                    self.performSegue(withIdentifier: "showContactToAddMember", sender: self)
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func fetchMemberFromServer() {
        if !allowFetchMore && realmMembers.count != 0 {
            return
        }
        allowFetchMore = false
        if self.roomType == .group {
            IGGlobal.prgShow(self.view)
            IGGroupGetMemberListRequest.Generator.generate(roomId: roomId, offset: Int32(realmMembers.count), limit: FETCH_MEMBER_LIMIT, filterRole: filterRole).success({ (protoResponse) in
                IGGlobal.prgHide()
                if let getGroupMemberList = protoResponse as? IGPGroupGetMemberListResponse {
                    if getGroupMemberList.igpMember.count != 0 {
                        self.allowFetchMore = true
                    }
                    IGGroupGetMemberListRequest.Handler.interpret(response: getGroupMemberList, roomId: self.roomId)
                }
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                if errorCode == .timeout {
                    self.allowFetchMore = true
                    self.fetchMemberFromServer()
                }
            }).send()
        } else if self.roomType == .channel {
            IGGlobal.prgShow(self.view)
            IGChannelGetMemberListRequest.Generator.generate(roomId: roomId, offset: Int32(realmMembers.count), limit: FETCH_MEMBER_LIMIT, filterRole: filterRole).success({ (protoResponse) in
                IGGlobal.prgHide()
                DispatchQueue.main.async {
                    if let getChannelMemberList = protoResponse as? IGPChannelGetMemberListResponse {
                        if getChannelMemberList.igpMember.count != 0 {
                            self.allowFetchMore = true
                        } else if self.realmMembers.count == 0 {
                            if self.filterRole == .admin {
                                self.tableView.setEmptyMessage("NOT_EXIST_ADMIN".localizedNew)
                            } else if self.filterRole == .moderator {
                                self.tableView.setEmptyMessage("NOT_EXIST_MODERATOR".localizedNew)
                            }
                        }
                        IGChannelGetMemberListRequest.Handler.interpret(response: getChannelMemberList, roomId: self.roomId)
                    }
                }
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                if errorCode == .timeout {
                    self.allowFetchMore = true
                    self.fetchMemberFromServer()
                }
            }).send()
        }
    }
    
    
    private func fetchUserInfo(userId: Int64){
        IGUserInfoRequest.sendRequestAvoidDuplicate(userId: userId) { (userInfo) in
            IGRealmMember.updateMemberInfo(roomId: self.roomId, user: userInfo)
        }
    }
    
    func openChat(room : IGRoom){
        let roomVC = IGMessageViewController.instantiateFromAppStroryboard(appStoryboard: .Main)
        roomVC.room = room
        roomVC.hidesBottomBarWhenPushed = true
        self.navigationController!.pushViewController(roomVC, animated: true)
    }
    
    private func removeButtonsUnderline(buttons: [UIButton]){
        for btn in buttons {
            btn.removeUnderline()
        }
    }
    
    func didPressMoreButton(member: IGRealmMember) {
        showAlertMoreOptions(member)
    }
    
    /**
     * detect according to myRole and type of room which actions can i do?
     * Hint: 'IGPChannelRoom.IGPRole' & 'IGPGroupRoom.IGPRole' types are same with together so we just check values with one of them
     */
    private func detectActionsPermission(memberRole: Int) -> (kickMember: Bool, addModerator: Bool, removeModerator: Bool, addAdmin: Bool, removeAdmin: Bool) {
        if myRole == IGPChannelRoom.IGPRole.owner.rawValue {
            
            if memberRole == IGPChannelRoom.IGPRole.admin.rawValue {
                return (false, false, false, false, true)
            } else if memberRole == IGPChannelRoom.IGPRole.moderator.rawValue {
                return (false, false, true, true, false)
            } else if memberRole == IGPChannelRoom.IGPRole.member.rawValue {
                return (true, true, false, true, false)
            }
            
        } else if myRole == IGPChannelRoom.IGPRole.admin.rawValue {
            
            if memberRole == IGPChannelRoom.IGPRole.moderator.rawValue {
                return (false, false, true, false, false)
            } else if memberRole == IGPChannelRoom.IGPRole.member.rawValue {
                return (true, true, false, false, false)
            }
            
        } else if myRole == IGPChannelRoom.IGPRole.moderator.rawValue && roomType != .channel {
            
            if memberRole == IGPChannelRoom.IGPRole.member.rawValue {
                if self.room?.groupRoom?.publicExtra != nil { // for public group moderator can't kick member BUT in private group & in channel allow to kick member
                    return (false, false, false, false, false)
                } else {
                    return (true, false, false, false, false)
                }
            }
        }
        
        return (false, false, false, false, false)
    }
    
    private func showAlertMoreOptions(_ member: IGRealmMember) {
        
        let permissions = detectActionsPermission(memberRole: member.role)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        
        let addAdmin = UIAlertAction(title: "SET_AS_ADMIN".localizedNew, style: .default, handler: { (action) in
            if self.roomType == .channel {
                self.requestToAddAdminInChannel(member)
            } else {
                self.requestToAddAdminInGroup(member)
            }
        })
        
        let removeAdmin = UIAlertAction(title: "REMOVE_ADMIN".localizedNew, style: .default, handler: { (action) in
            if self.roomType == .channel {
                self.kickAdminChannel(userId: member.userId)
            } else {
                self.kickAdmin(userId: member.userId)
            }
        })
        
        let addModerator = UIAlertAction(title: "SET_AS_MODERATOR".localizedNew, style: .default, handler: { (action) in
            if self.roomType == .channel {
                self.requestToAddModeratorInChannel(member)
            } else {
                self.requestToAddModeratorInGroup(member)
            }
        })
        
        let removeModerator = UIAlertAction(title: "REMOVE_MODERATOR".localizedNew, style: .default, handler: { (action) in
            if self.roomType == .channel {
                self.kickModeratorChannel(userId: member.userId)
            } else {
                self.kickModerator(userId: member.userId)
            }
        })
        
        let kickMember = UIAlertAction(title: "KICK_MEMBER".localizedNew, style: .default, handler: { (action) in
            if self.roomType == .channel {
                self.kickMemberChannel(userId: member.userId)
            } else {
                self.kickMember(userId: member.userId)
            }
        })
        
        let cancel = UIAlertAction(title: "CANCEL_BTN".localizedNew, style: .cancel, handler: nil)
        
        if permissions.addAdmin {
            alertController.addAction(addAdmin)
        }
        if permissions.removeAdmin {
            alertController.addAction(removeAdmin)
        }
        if permissions.addModerator {
            alertController.addAction(addModerator)
        }
        if permissions.removeModerator {
            alertController.addAction(removeModerator)
        }
        if permissions.kickMember {
            alertController.addAction(kickMember)
        }
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func kickAlert(title: String, message: String, alertClouser: @escaping ((_ state :AlertState) -> Void)){
        let option = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .destructive, handler: { (action) in
            alertClouser(AlertState.Ok)
        })
        let cancel = UIAlertAction(title: "GLOBAL_NO".localizedNew, style: .cancel, handler: { (action) in
            alertClouser(AlertState.No)
        })
        
        option.addAction(ok)
        option.addAction(cancel)
        self.present(option, animated: true, completion: nil)
    }
    
    //MARK: - Scroll Manager
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if allowFetchMore {
            if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                fetchMemberFromServer()
            }
        }
    }

    //MARK: - Channel Actions
    
    func kickAdminChannel(userId: Int64) {
        if let channelRoom = room {
            kickAlert(title: "REMOVE_ADMIN".localizedNew, message: "ARE_U_SURE_REMOVE_ADMIN".localizedNew, alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGChannelKickAdminRequest.Generator.generate(roomId: channelRoom.id , memberId: userId).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        DispatchQueue.main.async {
                            switch protoResponse {
                            case let channelKickAdminResponse as IGPChannelKickAdminResponse:
                                let _ = IGChannelKickAdminRequest.Handler.interpret( response : channelKickAdminResponse)
                                self.tableView.reloadData()
                            default:
                                break
                            }
                        }
                    }).error ({ (errorCode, waitTime) in
                        IGGlobal.prgHide()
                        switch errorCode {
                        case .timeout:
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        default:
                            break
                        }
                        
                    }).send()
                }
            })
        }
    }
    
    func kickModeratorChannel(userId: Int64) {
        if let channelRoom = room {
            kickAlert(title: "REMOVE_MODERATOR".localizedNew, message: "ARE_U_SURE_REMOVE_MODERATOR".localizedNew, alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGChannelKickModeratorRequest.Generator.generate(roomID: channelRoom.id, memberID: userId).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        if let channelKickModeratorResponse = protoResponse as? IGPChannelKickModeratorResponse {
                            IGChannelKickModeratorRequest.Handler.interpret(response : channelKickModeratorResponse)
                        }
                    }).error ({ (errorCode, waitTime) in
                        IGGlobal.prgHide()
                        switch errorCode {
                        case .timeout:
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        default:
                            break
                        }
                        
                    }).send()
                }
            })
        }
    }

    
    func kickMemberChannel(userId: Int64) {
        if let _ = room {
            kickAlert(title: "KICK_MEMBER".localizedNew, message: "ARE_U_SURE_KICK_USER".localizedNew, alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGChannelKickMemberRequest.Generator.generate(roomID: (self.room?.id)!, memberID: userId).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        if let kickMemberResponse = protoResponse as? IGPChannelKickMemberResponse {
                            IGChannelKickMemberRequest.Handler.interpret(response: kickMemberResponse)
                        }
                    }).error ({ (errorCode, waitTime) in
                        IGGlobal.prgHide()
                        switch errorCode {
                        case .timeout:
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        default:
                            break
                        }
                        
                    }).send()
                }
            })
        }
    }
    
    func requestToAddAdminInChannel(_ member: IGRealmMember) {
        if let channelRoom = room {
            IGGlobal.prgShow(self.view)
            IGChannelAddAdminRequest.Generator.generate(roomID: channelRoom.id, memberID: member.userId).success({ (protoResponse) in
                IGGlobal.prgHide()
                if let channelAddAdminResponse = protoResponse as? IGPChannelAddAdminResponse {
                    IGChannelAddAdminRequest.Handler.interpret(response: channelAddAdminResponse)
                }
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                case .canNotAddThisUserAsAdminToGroup:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: "There is an error to adding this contact in channel", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                default:
                    break
                }
                
            }).send()
        }
    }
    
    func requestToAddModeratorInChannel(_ member: IGRealmMember) {
        if let channelRoom = room {
            IGGlobal.prgShow(self.view)
            IGChannelAddModeratorRequest.Generator.generate(roomID: channelRoom.id, memberID: member.userId).success({ (protoResponse) in
                IGGlobal.prgHide()
                if let channelAddModeratorResponse = protoResponse as? IGPChannelAddModeratorResponse {
                    IGChannelAddModeratorRequest.Handler.interpret(response: channelAddModeratorResponse)
                }
                
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                case .canNotAddThisUserAsModeratorToGroup:
                    DispatchQueue.main.async {
                        let alertC = UIAlertController(title: "GLOBAL_WARNING".localizedNew, message: "UNSSUCCESS_OTP".localizedNew, preferredStyle: .alert)
                        
                        let cancel = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                        alertC.addAction(cancel)
                        self.present(alertC, animated: true, completion: nil)
                    }
                    
                default:
                    break
                }
                
            }).send()
        }
    }
    
    //MARK: - Group Actions
    func kickAdmin(userId: Int64) {
        if let groupRoom = room {
            kickAlert(title: "REMOVE_ADMIN".localizedNew, message: "ARE_U_SURE_REMOVE_ADMIN".localizedNew, alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGGroupKickAdminRequest.Generator.generate(roomID: groupRoom.id , memberID: userId).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        if let groupKickAdminResponse = protoResponse as? IGPGroupKickAdminResponse {
                            IGGroupKickAdminRequest.Handler.interpret( response : groupKickAdminResponse)
                        }
                    }).error ({ (errorCode, waitTime) in
                        IGGlobal.prgHide()
                        switch errorCode {
                        case .timeout:
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        default:
                            break
                        }
                    }).send()
                }
            })
        }
    }
    
    func kickModerator(userId: Int64) {
        if let groupRoom = room {
            kickAlert(title: "REMOVE_MODERATOR".localizedNew, message: "ARE_U_SURE_REMOVE_MODERATOR", alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGGroupKickModeratorRequest.Generator.generate(memberId: userId, roomId: groupRoom.id).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        if let groupKickModeratorResponse = protoResponse as? IGPGroupKickModeratorResponse {
                            IGGroupKickModeratorRequest.Handler.interpret( response : groupKickModeratorResponse)
                        }
                    }).error ({ (errorCode, waitTime) in
                        IGGlobal.prgHide()
                        switch errorCode {
                        case .timeout:
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        default:
                            break
                        }
                    }).send()
                }
            })
        }
    }
    
    func kickMember(userId: Int64) {
        if room != nil {
            kickAlert(title: "KICK_MEMBER".localizedNew, message: "ARE_U_SURE_KICK_USER".localizedNew, alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGGroupKickMemberRequest.Generator.generate(memberId: userId, roomId: (self.room?.id)!).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        if let kickMemberResponse = protoResponse as? IGPGroupKickMemberResponse {
                            IGGroupKickMemberRequest.Handler.interpret(response: kickMemberResponse)
                        }
                    }).error ({ (errorCode, waitTime) in
                        IGGlobal.prgHide()
                        switch errorCode {
                        case .timeout:
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        default:
                            break
                        }
                    }).send()
                }
            })
        }
    }
    
    
    func requestToAddAdminInGroup(_ member: IGRealmMember) {
        if let groupRoom = room {
            IGGlobal.prgShow(self.view)
            IGGroupAddAdminRequest.Generator.generate(roomID: groupRoom.id, memberID: member.userId).success({ (protoResponse) in
                IGGlobal.prgHide()
                if let grouplAddAdminResponse = protoResponse as? IGPGroupAddAdminResponse {
                    IGGroupAddAdminRequest.Handler.interpret(response: grouplAddAdminResponse)
                }
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                case .canNotAddThisUserAsAdminToGroup:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: "There is an error to adding this contact in group", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                default:
                    break
                }
                
            }).send()
        }
    }
    
    func requestToAddModeratorInGroup(_ member: IGRealmMember) {
        if let channelRoom = room {
            IGGlobal.prgShow(self.view)
            IGGroupAddModeratorRequest.Generator.generate(roomID: channelRoom.id, memberID: member.userId).success({ (protoResponse) in
                IGGlobal.prgHide()
                if let groupAddModeratorResponse = protoResponse as? IGPGroupAddModeratorResponse {
                    IGGroupAddModeratorRequest.Handler.interpret(response: groupAddModeratorResponse)
                }
                
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                case .canNotAddThisUserAsModeratorToGroup:
                    DispatchQueue.main.async {
                        let alertC = UIAlertController(title: "GLOBAL_WARNING".localizedNew, message: "UNSSUCCESS_OTP".localizedNew, preferredStyle: .alert)
                        
                        let cancel = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                        alertC.addAction(cancel)
                        self.present(alertC, animated: true, completion: nil)
                    }
                    
                default:
                    break
                }
                
            }).send()
        }
    }
    
    //MARK:- Observers
    func onUpdateMyRole(roomId: Int64, memberId: Int64, role: Int) {
        updateMyRoleAndPermissions(roomId: roomId, memberId: memberId, role: role)
    }
    
    //MARK:- Prepare Change Page
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if roomType == .group {
            if segue.identifier == "showContactToAddMember" {
                let destinationTv = segue.destination as! IGChooseMemberFromContactsToCreateGroupViewController
                destinationTv.mode = "Members"
                destinationTv.room = room
            }
            if segue.identifier == "GoToChangeGroupPublicLink" {
                let destination = segue.destination as! IGGroupInfoEditTypeTableViewController
                destination.room = room
            }

        } else {
            if segue.identifier == "showContactToAddMember" {
                let destinationTv = segue.destination as! IGChooseMemberFromContactsToCreateGroupViewController
                destinationTv.mode = "Members"
                destinationTv.room = room
            }
        }
    }
}
