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
import IGProtoBuff
import SnapKit

class IGAdminRightsTableViewController: BaseTableViewController {

    @IBOutlet weak var avatarView: IGAvatarView!
    @IBOutlet weak var contactInfoView: UIView!
    @IBOutlet weak var txtContactName: UILabel!
    @IBOutlet weak var txtContactStatus: UILabel!
    
    @IBOutlet weak var switchModifyRoom: UISwitch!
    @IBOutlet weak var switchPostMessage: UISwitch!
    @IBOutlet weak var switchSendTextMessage: UISwitch!
    @IBOutlet weak var switchSendMediaMessage: UISwitch!
    @IBOutlet weak var switchSendStickerMessage: UISwitch!
    @IBOutlet weak var switchSendGifMessage: UISwitch!
    @IBOutlet weak var switchSendLinkMessage: UISwitch!
    @IBOutlet weak var switchEditMessage: UISwitch!
    @IBOutlet weak var switchDeleteMessage: UISwitch!
    @IBOutlet weak var switchPinMessage: UISwitch!
    @IBOutlet weak var switchAddMember: UISwitch!
    @IBOutlet weak var switchBanMember: UISwitch!
    @IBOutlet weak var switchGetMember: UISwitch!
    @IBOutlet weak var switchAddAdmin: UISwitch!
    
    @IBOutlet weak var modifyRoomView: UIView!
    @IBOutlet weak var postMessageView: UIView!
    @IBOutlet weak var sendTextView: UIView!
    @IBOutlet weak var sendMediaView: UIView!
    @IBOutlet weak var sendStickerView: UIView!
    @IBOutlet weak var sendGifView: UIView!
    @IBOutlet weak var sendLinkView: UIView!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var pinView: UIView!
    @IBOutlet weak var showMemberView: UIView!
    @IBOutlet weak var addMemberView: UIView!
    @IBOutlet weak var banMemberView: UIView!
    @IBOutlet weak var addAdminView: UIView!
    
    @IBOutlet weak var txtModifyRoom: UILabel!
    @IBOutlet weak var txtPostMessage: UILabel!
    @IBOutlet weak var txtSendTextMessage: UILabel!
    @IBOutlet weak var txtSendMediaMessage: UILabel!
    @IBOutlet weak var txtSendStickerMessage: UILabel!
    @IBOutlet weak var txtSendGifMessage: UILabel!
    @IBOutlet weak var txtSendLinkMessage: UILabel!
    @IBOutlet weak var txtEditMessage: UILabel!
    @IBOutlet weak var txtDeleteMessage: UILabel!
    @IBOutlet weak var txtPinMessage: UILabel!
    @IBOutlet weak var txtGetMember: UILabel!
    @IBOutlet weak var txtAddMember: UILabel!
    @IBOutlet weak var txtBanMember: UILabel!
    @IBOutlet weak var txtAddAdmin: UILabel!
    @IBOutlet weak var txtDismissAdmin: UILabel!
    
    var userInfo: IGRegisteredUser?
    var room: IGRoom!
    var memberEditType: MemberEditTypes!
    var myRole: Int!
    private var roomAccessDefault: IGPRoomAccess!
    
    @IBAction func OnPostMessageChange(_ sender: UISwitch) {
        self.managePostAndEdit(state: sender.isOn)
    }
    
    @IBAction func OnSendTextMessageChange(_ sender: UISwitch) {
        self.managePostAndEdit(state: sender.isOn)
    }
    
    @IBAction func onGetMemberChange(_ sender: UISwitch) {
        self.manageGetMemberAndOtherOptions(state: sender.isOn)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initNavigationBar()
        manageStrings()
        if userInfo != nil {
            avatarView.setUser(userInfo!)
            txtContactName.text = userInfo!.displayName
            txtContactStatus.text = IGRegisteredUser.IGLastSeenStatus.fromIGP(status: userInfo?.lastSeenStatus, lastSeen: userInfo?.lastSeen)
            if isRTL {
                txtContactName.textAlignment = .right
            } else {
                txtContactName.textAlignment = .left
            }
        }
        fillRoomAccess()
        manageEnableItems()
    }
    
    func initNavigationBar(){
        var title = IGStringsManager.AdminRights.rawValue.localized
        if memberEditType == MemberEditTypes.EditMember {
            title = IGStringsManager.MemberRights.rawValue.localized
        } else if memberEditType == MemberEditTypes.EditRoom {
            title = IGStringsManager.RoomRights.rawValue.localized
        }
        
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: "", rightItemFontSize: 30, title: title, iGapFont: true)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        navigationItem.rightViewContainer?.addAction { [weak self] in
            self?.requestToAddAdminInChannel()
        }
    }
    
    private func manageStrings(){
        txtModifyRoom.text = IGStringsManager.ModifyRoom.rawValue.localized
        txtPostMessage.text = IGStringsManager.PostMessage.rawValue.localized
        txtSendTextMessage.text = IGStringsManager.SendText.rawValue.localized
        txtSendMediaMessage.text = IGStringsManager.SendMedia.rawValue.localized
        txtSendGifMessage.text = IGStringsManager.SendGif.rawValue.localized
        txtSendStickerMessage.text = IGStringsManager.SendSticker.rawValue.localized
        txtSendLinkMessage.text = IGStringsManager.SendLink.rawValue.localized
        txtEditMessage.text = IGStringsManager.EditMessage.rawValue.localized
        txtDeleteMessage.text = IGStringsManager.DeleteMessage.rawValue.localized
        txtPinMessage.text = IGStringsManager.PinMessage.rawValue.localized
        txtGetMember.text = IGStringsManager.ShowMember.rawValue.localized
        txtAddMember.text = IGStringsManager.AddMember.rawValue.localized
        txtBanMember.text = IGStringsManager.RemoveUser.rawValue.localized
        txtAddAdmin.text = IGStringsManager.AddAdmin.rawValue.localized
        txtDismissAdmin.text = IGStringsManager.RemoveAdmin.rawValue.localized
    }
    
    private func disableItem(view: UIView, label: UILabel, switchItem: UISwitch) {
        view.backgroundColor = UIColor.lightGray.lighter(by: 20)
        label.textColor = UIColor.gray
        switchItem.setOn(false, animated: true)
        switchItem.isUserInteractionEnabled = false
    }
    
    private func enableItem(view: UIView, label: UILabel, switchItem: UISwitch) {
        view.backgroundColor = contactInfoView.backgroundColor
        label.textColor = txtContactName.textColor
        switchItem.isUserInteractionEnabled = true
    }
    
    private func managePostAndEdit(state: Bool){
        if state {
            if let myAccess = IGRealmRoomAccess.getRoomAccess(roomId: room.id, userId: IGAppManager.sharedManager.userID()!) {
                if myAccess.editMessage {
                    enableItem(view: editView, label: txtEditMessage, switchItem: switchEditMessage)
                }
                if myAccess.postMessageRights.sendMedia {
                    enableItem(view: sendMediaView, label: txtSendMediaMessage, switchItem: switchSendMediaMessage)
                }
                if myAccess.postMessageRights.sendGif {
                    enableItem(view: sendGifView, label: txtSendGifMessage, switchItem: switchSendGifMessage)
                }
                if myAccess.postMessageRights.sendSticker {
                    enableItem(view: sendStickerView, label: txtSendStickerMessage, switchItem: switchSendStickerMessage)
                }
                if myAccess.postMessageRights.sendLink {
                    enableItem(view: sendLinkView, label: txtSendLinkMessage, switchItem: switchSendLinkMessage)
                }
            }
            
        } else {
            disableItem(view: editView, label: txtEditMessage, switchItem: switchEditMessage)
            disableItem(view: sendMediaView, label: txtSendMediaMessage, switchItem: switchSendMediaMessage)
            disableItem(view: sendGifView, label: txtSendGifMessage, switchItem: switchSendGifMessage)
            disableItem(view: sendStickerView, label: txtSendStickerMessage, switchItem: switchSendStickerMessage)
            disableItem(view: sendLinkView, label: txtSendLinkMessage, switchItem: switchSendLinkMessage)
        }
    }
    
    private func manageGetMemberAndOtherOptions(state: Bool){
        if state {
            if let myAccess = IGRealmRoomAccess.getRoomAccess(roomId: room.id, userId: IGAppManager.sharedManager.userID()!) {
                if myAccess.addMember {
                    enableItem(view: addMemberView, label: txtAddMember, switchItem: switchAddMember)
                } else {
                    disableItem(view: addMemberView, label: txtAddMember, switchItem: switchAddMember)
                }
                
                if myAccess.banMember {
                    enableItem(view: banMemberView, label: txtBanMember, switchItem: switchBanMember)
                } else {
                    disableItem(view: banMemberView, label: txtBanMember, switchItem: switchBanMember)
                }
                
                if myAccess.addAdmin {
                    enableItem(view: addAdminView, label: txtAddAdmin, switchItem: switchAddAdmin)
                } else {
                    disableItem(view: addAdminView, label: txtAddAdmin, switchItem: switchAddAdmin)
                }
            }
        } else {
            disableItem(view: addMemberView, label: txtAddMember, switchItem: switchAddMember)
            disableItem(view: banMemberView, label: txtBanMember, switchItem: switchBanMember)
            disableItem(view: addAdminView, label: txtAddAdmin, switchItem: switchAddAdmin)
        }
    }
    
    /** check for enable or disable items for admin rights opiton **/
    private func manageEnableItems(){
        if myRole == IGPChannelRoom.IGPRole.owner.rawValue {
            return
        }
        
        if let myAccess = IGRealmRoomAccess.getRoomAccess(roomId: room.id, userId: IGAppManager.sharedManager.userID()!) {
            if !myAccess.modifyRoom {
                disableItem(view: modifyRoomView, label: txtModifyRoom, switchItem: switchModifyRoom)
            }
            if room.type == .channel {
                if !myAccess.postMessageRights.sendText {
                    disableItem(view: postMessageView, label: txtPostMessage, switchItem: switchPostMessage)
                }
            } else if room.type == .group {
                if !myAccess.postMessageRights.sendText {
                    disableItem(view: sendTextView, label: txtSendTextMessage, switchItem: switchSendTextMessage)
                }
                if !myAccess.postMessageRights.sendMedia {
                    disableItem(view: sendMediaView, label: txtSendMediaMessage, switchItem: switchSendMediaMessage)
                }
                if !myAccess.postMessageRights.sendGif {
                    disableItem(view: sendGifView, label: txtSendGifMessage, switchItem: switchSendGifMessage)
                }
                if !myAccess.postMessageRights.sendSticker {
                    disableItem(view: sendStickerView, label: txtSendStickerMessage, switchItem: switchSendStickerMessage)
                }
                if !myAccess.postMessageRights.sendLink {
                    disableItem(view: sendLinkView, label: txtSendLinkMessage, switchItem: switchSendLinkMessage)
                }
            }
            if !myAccess.editMessage {
                disableItem(view: editView, label: txtEditMessage, switchItem: switchEditMessage)
            }
            if !myAccess.deleteMessage {
                disableItem(view: deleteView, label: txtDeleteMessage, switchItem: switchDeleteMessage)
            }
            if !myAccess.pinMessage {
                disableItem(view: pinView, label: txtPinMessage, switchItem: switchPinMessage)
            }
            if !myAccess.getMember {
                disableItem(view: showMemberView, label: txtGetMember, switchItem: switchGetMember)
            }
            if !myAccess.addMember {
                disableItem(view: addMemberView, label: txtAddMember, switchItem: switchAddMember)
            }
            if !myAccess.postMessageRights.sendLink {
                disableItem(view: banMemberView, label: txtBanMember, switchItem: switchBanMember)
            }
            if !myAccess.postMessageRights.sendLink {
                disableItem(view: addAdminView, label: txtAddAdmin, switchItem: switchAddAdmin)
            }
        }
    }
    
    private func fillRoomAccess(){
        
        if memberEditType == .AddAdmin {
            switchModifyRoom.isOn = true
            switchPostMessage.isOn = true
            switchEditMessage.isOn = true
            switchDeleteMessage.isOn = true
            switchPinMessage.isOn = true
            switchGetMember.isOn = true
            switchAddMember.isOn = true
            switchBanMember.isOn = false
            switchAddAdmin.isOn = false
            return
        }
        
        if let roomAccess = IGRealmRoomAccess.getRoomAccess(roomId: room.id, userId: userInfo?.id ?? 0) {
            switchModifyRoom.isOn = roomAccess.modifyRoom
            if room.type == .channel {
                switchPostMessage.isOn = roomAccess.postMessageRights.sendText
            } else if room.type == .group {
                switchSendTextMessage.isOn = roomAccess.postMessageRights.sendText
                switchSendMediaMessage.isOn = roomAccess.postMessageRights.sendMedia
                switchSendStickerMessage.isOn = roomAccess.postMessageRights.sendSticker
                switchSendGifMessage.isOn = roomAccess.postMessageRights.sendGif
                switchSendLinkMessage.isOn = roomAccess.postMessageRights.sendLink
            }
            switchEditMessage.isOn = roomAccess.editMessage
            switchDeleteMessage.isOn = roomAccess.deleteMessage
            switchPinMessage.isOn = roomAccess.pinMessage
            switchAddMember.isOn = roomAccess.addMember
            switchBanMember.isOn = roomAccess.banMember
            switchGetMember.isOn = roomAccess.getMember
            switchAddAdmin.isOn = roomAccess.addAdmin
        }
        
        managePostAndEdit(state: switchSendTextMessage.isOn || switchPostMessage.isOn)
        manageGetMemberAndOtherOptions(state: switchGetMember.isOn)
    }
    
    private func makeChannelAdminRights() -> IGPChannelAddAdmin.IGPAdminRights {
        var adminRights = IGPChannelAddAdmin.IGPAdminRights()
        adminRights.igpModifyRoom = self.switchModifyRoom.isOn
        adminRights.igpPostMessage = self.switchPostMessage.isOn
        adminRights.igpEditMessage = self.switchEditMessage.isOn
        adminRights.igpDeleteMessage = self.switchDeleteMessage.isOn
        adminRights.igpPinMessage = self.switchPinMessage.isOn
        adminRights.igpGetMember = self.switchGetMember.isOn
        adminRights.igpAddMember = self.switchAddMember.isOn
        adminRights.igpBanMember = self.switchBanMember.isOn
        adminRights.igpAddAdmin = self.switchAddAdmin.isOn
        return adminRights
    }
    
    private func makeGroupAdminRights() -> IGPGroupAddAdmin.IGPAdminRights{
        var adminRights = IGPGroupAddAdmin.IGPAdminRights()
        adminRights.igpDeleteMessage = self.switchDeleteMessage.isOn
        adminRights.igpPinMessage = self.switchPinMessage.isOn
        adminRights.igpGetMember = self.switchGetMember.isOn
        adminRights.igpAddMember = self.switchAddMember.isOn
        adminRights.igpBanMember = self.switchBanMember.isOn
        adminRights.igpAddAdmin = self.switchAddAdmin.isOn
        return adminRights
    }
    
    private func makeGroupMemberRights() -> IGPGroupChangeMemberRights.IGPMemberRights{
        var memberRights = IGPGroupChangeMemberRights.IGPMemberRights()
        memberRights.igpSendText = self.switchSendTextMessage.isOn
        memberRights.igpSendMedia = self.switchSendMediaMessage.isOn
        memberRights.igpSendSticker = self.switchSendStickerMessage.isOn
        memberRights.igpSendGif = self.switchSendGifMessage.isOn
        memberRights.igpSendLink = self.switchSendLinkMessage.isOn
        memberRights.igpPinMessage = self.switchPinMessage.isOn
        memberRights.igpGetMember = self.switchGetMember.isOn
        memberRights.igpAddMember = self.switchAddMember.isOn
        return memberRights
    }
    
    private func hasEnableState() -> Bool {
        return switchModifyRoom.isOn ||
            switchPostMessage.isOn ||
            switchSendTextMessage.isOn ||
            switchSendMediaMessage.isOn ||
            switchSendStickerMessage.isOn ||
            switchSendLinkMessage.isOn ||
            switchEditMessage.isOn ||
            switchDeleteMessage.isOn ||
            switchPinMessage.isOn ||
            switchAddMember.isOn ||
            switchBanMember.isOn ||
            switchGetMember.isOn ||
            switchAddAdmin.isOn
    }
    
    func requestToAddAdminInChannel() {
        
        if memberEditType == .AddAdmin && !hasEnableState() {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        if memberEditType == .EditAdmin && !hasEnableState() {
            kickAdmin()
            return
        }
        
        if room.type == .group {
            if memberEditType == .EditAdmin || memberEditType == .AddAdmin {
                if userInfo == nil {
                    return
                }
                IGGlobal.prgShow(self.view)
                IGGroupAddAdminRequest.Generator.generate(roomID: room.id, memberID: userInfo!.id, adminRights: makeGroupAdminRights()).success({ [weak self] (protoResponse) in
                    IGGlobal.prgHide()
                    if let grouplAddAdminResponse = protoResponse as? IGPGroupAddAdminResponse {
                        IGGroupAddAdminRequest.Handler.interpret(response: grouplAddAdminResponse)
                        DispatchQueue.main.async {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }).error ({ (errorCode, waitTime) in
                    IGGlobal.prgHide()
                    switch errorCode {
                    case .timeout:
                        DispatchQueue.main.async {
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.GlobalTryAgain.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
                        }
                    case .canNotAddThisUserAsAdminToGroup:
                        DispatchQueue.main.async {
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.GlobalTryAgain.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
                            
                        }
                    default:
                        break
                    }
                }).send()
            } else {
                IGGlobal.prgShow(self.view)
                IGGroupChangeMemberRightsRequest.Generator.generate(roomId: room.id, userId: userInfo?.id ?? 0, memberRights: makeGroupMemberRights()).success({ [weak self] (protoResponse) in
                    IGGlobal.prgHide()
                    if let memberRightsResponse = protoResponse as? IGPGroupChangeMemberRightsResponse {
                        IGGroupChangeMemberRightsRequest.Handler.interpret(response: memberRightsResponse)
                        DispatchQueue.main.async {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }).error ({ (errorCode, waitTime) in
                    IGGlobal.prgHide()
                    switch errorCode {
                    case .timeout:
                        DispatchQueue.main.async {
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.GlobalTryAgain.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
                        }
                    case .canNotAddThisUserAsAdminToGroup:
                        DispatchQueue.main.async {
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.GlobalTryAgain.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
                            
                        }
                    default:
                        break
                    }
                }).send()
            }
        } else if room.type == .channel {
            if userInfo == nil {
                return
            }
            IGGlobal.prgShow(self.view)
            IGChannelAddAdminRequest.Generator.generate(roomID: room.id, memberID: userInfo!.id, adminRights: makeChannelAdminRights()).success({ [weak self] (protoResponse) in
                IGGlobal.prgHide()
                if let channelAddAdminResponse = protoResponse as? IGPChannelAddAdminResponse {
                    IGChannelAddAdminRequest.Handler.interpret(response: channelAddAdminResponse)
                    DispatchQueue.main.async {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }).error ({ (errorCode, waitTime) in
                IGGlobal.prgHide()
                switch errorCode {
                case .timeout:
                    break
                case .canNotAddThisUserAsAdminToGroup:
                    DispatchQueue.main.async {
                        IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.GlobalTryAgain.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
                    }
                default:
                    break
                }
            }).send()
        }
    }
    
    
    func kickAdmin() {
        if room.type == .group {
            IGHelperAlert.shared.showCustomAlert(view: self, alertType: .question, title: IGStringsManager.RemoveAdmin.rawValue.localized, showIconView: true, showDoneButton: true, showCancelButton: true, message: IGStringsManager.SureToRemoveAdminRoleFrom.rawValue.localized, doneText: IGStringsManager.GlobalOK.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized, done: { [weak self] in
                if self == nil {
                    return
                }
                IGGlobal.prgShow(self!.view)
                IGGroupKickAdminRequest.Generator.generate(roomID: self!.room.id, memberID: self!.userInfo?.id ?? 0).success({ (protoResponse) in
                    IGGlobal.prgHide()
                    if let groupKickAdminResponse = protoResponse as? IGPGroupKickAdminResponse {
                        IGGroupKickAdminRequest.Handler.interpret( response : groupKickAdminResponse)
                        DispatchQueue.main.async {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }).error ({ (errorCode, waitTime) in
                    IGGlobal.prgHide()
                    switch errorCode {
                    case .timeout:
                        break
                    default:
                        break
                    }
                }).send()
            })
            
        } else if room.type == .channel {
            IGHelperAlert.shared.showCustomAlert(view: self, alertType: .question, title: IGStringsManager.RemoveAdmin.rawValue.localized, showIconView: true, showDoneButton: true, showCancelButton: true, message: IGStringsManager.SureToRemoveAdminRoleFrom.rawValue.localized, doneText: IGStringsManager.GlobalOK.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized, done: { [weak self] in
                if self == nil {
                    return
                }
                IGGlobal.prgShow(self!.view)
                IGChannelKickAdminRequest.Generator.generate(roomId: self!.room.id, memberId: self!.userInfo?.id ?? 0).success({ [weak self] (protoResponse) in
                    IGGlobal.prgHide()
                    if let channelKickAdminResponse = protoResponse as? IGPChannelKickAdminResponse {
                        let _ = IGChannelKickAdminRequest.Handler.interpret(response: channelKickAdminResponse)
                        DispatchQueue.main.async {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }).error ({ (errorCode, waitTime) in
                    IGGlobal.prgHide()
                    switch errorCode {
                    case .timeout:
                        break
                    default:
                        break
                    }
                    
                }).send()
            })
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if memberEditType == .EditRoom {
                return 0
            }
            return 80
        } else {
            return 48
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if memberEditType == .EditAdmin {
            return 3
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            if room.type == .group {
                if memberEditType == .AddAdmin || memberEditType == .EditAdmin {
                    return super.tableView(tableView, cellForRowAt: IndexPath(row: indexPath.row + 8, section: 1))
                } else {
                    if indexPath.row >= 5 {
                        return super.tableView(tableView, cellForRowAt: IndexPath(row: indexPath.row + 4, section: 1))
                    } else {
                        return super.tableView(tableView, cellForRowAt: IndexPath(row: indexPath.row + 2, section: 1))
                    }
                }
            }
            
            if room.type == .channel {
                if indexPath.row >= 2 {
                    return super.tableView(tableView, cellForRowAt: IndexPath(row: indexPath.row + 5, section: 1))
                }
            }
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            if room.type == .channel {
                return 9
            } else if room.type == .group {
                if memberEditType == .AddAdmin || memberEditType == .EditAdmin {
                    return 6
                } else {
                    return 8
                }
            }
        } else if section == 2 {
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let headerView = UIView()
            headerView.backgroundColor = ThemeManager.currentTheme.TableViewCellColor
            let headerTitle = UILabel()
            if self.isRTL {
                headerTitle.textAlignment = .right
            } else {
                headerTitle.textAlignment = .left
            }
            headerView.addSubview(headerTitle)
            headerTitle.font = UIFont.igFont(ofSize: 17, weight: .bold)
            headerTitle.textColor = UIColor.iGapBlue()
            if memberEditType == .EditMember {
                headerTitle.text = IGStringsManager.WhatCanThisMemberDo.rawValue.localized
            } else if memberEditType == .EditRoom {
                headerTitle.text = IGStringsManager.EditRoomRights.rawValue.localized
            } else {
                headerTitle.text = IGStringsManager.WhatCanThisAdminDo.rawValue.localized
            }
            headerTitle.adjustsFontSizeToFitWidth = true
            headerTitle.minimumScaleFactor = 0.5
            
            headerTitle.snp.makeConstraints { (make) in
                make.leading.equalTo(headerView.snp.leading).offset(20)
                make.trailing.equalTo(headerView.snp.trailing).offset(-20)
                make.height.equalTo(25)
                make.centerY.equalTo(headerView.snp.centerY)
            }
            return headerView
        }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if memberEditType == .EditRoom {
                return 0
            }
            return 20
        } else if section == 1 {
            return 35
        } else if section == 2 {
            return 0
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = ThemeManager.currentTheme.TableViewCellColor
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if userInfo != nil {
                IGHelperChatOpener.openUserProfile(user: userInfo!)
            }
        } else if indexPath.section == 2 {
            kickAdmin()
        }
    }
}
