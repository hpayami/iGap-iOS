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

class IGGroupInfoMemberListTableViewController: BaseTableViewController,cellWithMore  {
    
    
    
    var allMember = [IGGroupMember]()
    var room : IGRoom?
    var hud = MBProgressHUD()
    var filterRole : IGRoomFilterRole = .all
    var members : Results<IGGroupMember>!
    var notificationToken: NotificationToken?
    var myRole : IGGroupMember.IGRole?
    var roomId: Int64!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myRole = room?.groupRoom?.role
        roomId = room?.id
        let predicate = NSPredicate(format: "roomID = %lld", (room?.id)!)
        members =  try! Realm().objects(IGGroupMember.self).filter(predicate)
        self.notificationToken = members.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.tableView.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                // Query messages have changed, so apply them to the TableView
//                self.tableView.reloadData()
                self.tableView.reloadData()

                break
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
                break
            }
        }
        setNavigationItem()
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
    
    override func viewWillAppear(_ animated: Bool) {
        fetchGroupMemberFromServer()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell", for: indexPath) as! IGGroupInfoMemberListTableViewCell
        
        let member = members[indexPath.row]
        cell.setUser(member,myRole: myRole)
        cell.delegate = self
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let roomU = IGRoom.existRoomInLocal(userId: self.members[indexPath.row].userID) {
            openChat(room: roomU)
        } else { //dont have chat
            IGGlobal.prgShow(self.view)
            IGChatGetRoomRequest.Generator.generate(peerId: self.members[indexPath.row].userID).success({ (protoResponse) in
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
    
    func openChat(room : IGRoom){
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let roomVC = storyboard.instantiateViewController(withIdentifier: "IGMessageViewController") as! IGMessageViewController
        roomVC.room = room
        //        IGFactory.shared.updateRoomLastMessageIfPossible(roomID: room.id)
        
        self.navigationController!.pushViewController(roomVC, animated: true)
    }
    
    
    
    private func removeButtonsUnderline(buttons: [UIButton]){
        for btn in buttons {
            btn.removeUnderline()
        }
    }
    func didPressMoreButton(member: IGGroupMember) {
        showAlertMoreOptions(member)
    }
    
    
    private func showAlertMoreOptions(_ member: IGGroupMember) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        
 
        if myRole == .owner {
            if member.role == .admin {
                let optionOne = UIAlertAction(title: "REMOVE_ADMIN".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.kickAdmin(userId: member.user!.id)
                    }
                })
                let optionTwo = UIAlertAction(title: "KICK_MEMBER".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.kickMember(userId: member.user!.id)
                    }
                })
                
                let cancel = UIAlertAction(title: "CANCEL_BTN".localizedNew, style: .cancel, handler: nil)
                
                alertController.addAction(optionOne)
                alertController.addAction(optionTwo)
                alertController.addAction(cancel)
                
                self.present(alertController, animated: true, completion: nil)
                return
                
                
            }
            if member.role == .moderator {
                let optionOne = UIAlertAction(title: "REMOVE_MODERATOR".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.kickModerator(userId: member.userID)
                    }
                })
                let optionTwo = UIAlertAction(title: "KICK_MEMBER".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.kickMember(userId: member.user!.id)
                    }
                })
                
                let cancel = UIAlertAction(title: "CANCEL_BTN".localizedNew, style: .cancel, handler: nil)
                
                alertController.addAction(optionOne)
                alertController.addAction(optionTwo)
                alertController.addAction(cancel)
                
                self.present(alertController, animated: true, completion: nil)
                return
                
                
            }
            if member.role == .member {
                let optionOne = UIAlertAction(title: "SET_AS_ADMIN".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.requestToAddAdminInGroup(member)
                    }
                })
                let optionTwo = UIAlertAction(title: "SET_AS_MODERATOR".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.requestToAddModeratorInGroup(member)
                    }
                })
                let optionThree = UIAlertAction(title: "KICK_MEMBER".localizedNew, style: .default, handler: { (action) in
                    //            self.changedChannelTypeToPublic()
                    if self.room?.type == .channel {
                    } else {
                        self.kickMember(userId: member.user!.id)
                    }
                })
                
                let cancel = UIAlertAction(title: "CANCEL_BTN".localizedNew, style: .cancel, handler: nil)
                
                alertController.addAction(optionOne)
                alertController.addAction(optionTwo)
                alertController.addAction(optionThree)
                alertController.addAction(cancel)
                
                self.present(alertController, animated: true, completion: nil)
                return
                
                
            }
        } else if myRole == .admin {
            
            if member.role == .moderator {
                let optionOne = UIAlertAction(title: "REMOVE_MODERATOR".localizedNew, style: .default, handler: { (action) in
                    if self.room?.type == .channel {
                    } else {
                        self.kickModerator(userId: member.user!.id)
                    }
                })
                let optionTwo = UIAlertAction(title: "KICK_MEMBER".localizedNew, style: .default, handler: { (action) in
                    //            self.changedChannelTypeToPublic()
                    if self.room?.type == .channel {
                    } else {
                        self.kickMember(userId: member.user!.id)
                    }
                })
                
                let cancel = UIAlertAction(title: "CANCEL_BTN".localizedNew, style: .cancel, handler: nil)
                
                alertController.addAction(optionOne)
                alertController.addAction(optionTwo)
                alertController.addAction(cancel)
                
                self.present(alertController, animated: true, completion: nil)
                return
                
                
            }
            if member.role == .member {
                let optionOne = UIAlertAction(title: "SET_AS_ADMIN".localizedNew, style: .default, handler: { (action) in
                    //            self.changedChannelTypeToPublic()
                    if self.room?.type == .channel {
                    } else {
                        self.requestToAddAdminInGroup(member)
                    }
                })
                let optionTwo = UIAlertAction(title: "SET_AS_MODERATOR".localizedNew, style: .default, handler: { (action) in
                    //            self.changedChannelTypeToPublic()
                    if self.room?.type == .channel {
                    } else {
                        self.requestToAddModeratorInGroup(member)
                    }
                })
                let optionThree = UIAlertAction(title: "KICK_MEMBER".localizedNew, style: .default, handler: { (action) in
                    //            self.changedChannelTypeToPublic()
                    if self.room?.type == .channel {
                    } else {
                        self.kickMember(userId: member.user!.id)
                    }
                })
                
                let cancel = UIAlertAction(title: "CANCEL_BTN".localizedNew, style: .cancel, handler: nil)
                
                alertController.addAction(optionOne)
                alertController.addAction(optionTwo)
                alertController.addAction(optionThree)
                alertController.addAction(cancel)
                
                self.present(alertController, animated: true, completion: nil)
                return
                
                
            }
        }
        
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
    
    
    //    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    //        if tableView.isEditing == true {
    //            if let selectedMemberId = members[indexPath.row].user?.id {
    //                self.kickMember(memberUserId: selectedMemberId)
    //            }
    //        }
    //    }
    //
    //    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    //        var defualtEditingStyle : UITableViewCellEditingStyle = .none
    //        if room?.groupRoom?.type == .privateRoom {
    //            if myRole == .admin || myRole == .moderator || myRole == .owner {
    //                defualtEditingStyle =  .delete
    //            } else {
    //                defualtEditingStyle =  .none
    //            }
    //        } else if room?.groupRoom?.type == .publicRoom {
    //            if myRole == .admin || myRole == .owner {
    //                defualtEditingStyle =  .delete
    //            } else {
    //                defualtEditingStyle =  .none
    //            }
    //        }
    //        return defualtEditingStyle
    //    }
    
    func kickAdmin(userId: Int64) {
        if let groupRoom = room {
            kickAlert(title: "REMOVE_ADMIN".localizedNew, message: "ARE_U_SURE_REMOVE_ADMIN".localizedNew, alertClouser: { (state) -> Void in
                if state == AlertState.Ok {
                    IGGlobal.prgShow(self.view)
                    IGGroupKickAdminRequest.Generator.generate(roomID: groupRoom.id , memberID: userId).success({ (protoResponse) in
                        IGGlobal.prgHide()
                        DispatchQueue.main.async {
                            switch protoResponse {
                            case let groupKickAdminResponse as IGPGroupKickAdminResponse:
                                IGGroupKickAdminRequest.Handler.interpret( response : groupKickAdminResponse)
                            default:
                                break
                            }
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
                        DispatchQueue.main.async {
                            switch protoResponse {
                            case let groupKickModeratorResponse as IGPGroupKickModeratorResponse:
                                IGGroupKickModeratorRequest.Handler.interpret( response : groupKickModeratorResponse)
                            default:
                                break
                            }
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
                        DispatchQueue.main.async {
                            if let kickMemberResponse = protoResponse as? IGPGroupKickMemberResponse {
                                IGGroupKickMemberRequest.Handler.interpret(response: kickMemberResponse)
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
    
    
    func requestToAddAdminInGroup(_ member: IGGroupMember) {
            if let groupRoom = room {
                IGGlobal.prgShow(self.view)
                IGGroupAddAdminRequest.Generator.generate(roomID: groupRoom.id, memberID: member.user!.id).success({ (protoResponse) in
                    IGGlobal.prgHide()
                    DispatchQueue.main.async {
                        if let channelAddAdminResponse = protoResponse as? IGPGroupAddAdminResponse {
                            IGGroupAddAdminRequest.Handler.interpret(response: channelAddAdminResponse, memberRole: .admin)
                        }
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
    
    func requestToAddModeratorInGroup(_ member: IGGroupMember) {

            if let channelRoom = room {
                IGGlobal.prgShow(self.view)
                IGGroupAddModeratorRequest.Generator.generate(roomID: channelRoom.id, memberID: member.user!.id).success({ (protoResponse) in
                    IGGlobal.prgHide()
                    DispatchQueue.main.async {
                        if let groupAddModeratorResponse = protoResponse as? IGPGroupAddModeratorResponse {
                            IGGroupAddModeratorRequest.Handler.interpret(response: groupAddModeratorResponse, memberRole: .moderator)
                        }
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
    
    func fetchGroupMemberFromServer() {
        IGGlobal.prgShow(self.view)
        IGGroupGetMemberListRequest.Generator.generate(roomId: roomId, offset: Int32(self.allMember.count), limit: 40, filterRole: filterRole).success({ (protoResponse) in
            IGGlobal.prgHide()
            DispatchQueue.main.async {
                switch protoResponse {
                case let getGroupMemberList as IGPGroupGetMemberListResponse:
                    let igpMembers =  IGGroupGetMemberListRequest.Handler.interpret(response: getGroupMemberList, roomId: (self.room?.id)!)
                    for member in igpMembers {
                        let igmember = IGGroupMember(igpMember: member, roomId: self.roomId)
                        self.allMember.append(igmember)
                    }
                    self.hud.hide(animated: true)
                default:
                    break
                }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContactToAddMember" {
            let destinationTv = segue.destination as! IGChooseMemberFromContactsToCreateGroupViewController
            destinationTv.mode = "Members"
            destinationTv.room = room
        }
        if segue.identifier == "GoToChangeGroupPublicLink" {
            let destination = segue.destination as! IGGroupInfoEditTypeTableViewController
            destination.room = room
        }
    }
}
