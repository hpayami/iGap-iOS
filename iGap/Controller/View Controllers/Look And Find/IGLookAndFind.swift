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
import SwiftProtobuf
import RealmSwift

class IGLookAndFind: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate , UINavigationControllerDelegate , UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.change(textFont: UIFont.igFont(ofSize: 15))
//            (searchBar.value(forKey: "cancelButton") as? UIButton)?.setTitle(IGStringsManager.GlobalCancel.rawValue.localized, for: .normal)
        }
    }

    static var enableForward = false //open forward page or main tab due to the this value
    var findResult: [IGLookAndFindStruct] = []
    var searching = false // use this param for avoid from duplicate search
    var latestSearchText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let searchBarCancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            searchBarCancelButton.setTitle(IGStringsManager.GlobalCancel.rawValue.localized, for: .normal)
            searchBarCancelButton.titleLabel!.font = UIFont.igFont(ofSize: 14, weight: .bold)
            searchBarCancelButton.tintColor = ThemeManager.currentTheme.LabelColor
        }
        
        searchBar.delegate = self
        setNavigationItem()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        tableView.tableHeaderView?.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        self.view.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        
        IGHelperView.makeSearchView(searchBar: searchBar)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchBar.becomeFirstResponder()
        }
//        (searchBar.value(forKey: "cancelButton") as? UIButton)?.setTitle(IGStringsManager.GlobalCancel.rawValue.localized, for: .normal)

        initTheme()
    }
    private func initTheme() {
        self.tableView.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let attributes:[NSAttributedString.Key:Any] = [
            NSAttributedString.Key.foregroundColor : ThemeManager.currentTheme.LabelColor,
            NSAttributedString.Key.font : UIFont.igFont(ofSize: 15)
        ]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
//        (searchBar.value(forKey: "cancelButton") as? UIButton)?.setTitle(IGStringsManager.GlobalCancel.rawValue.localized, for: .normal)

        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        (searchBar.value(forKey: "cancelButton") as? UIButton)?.setTitle(IGStringsManager.GlobalCancel.rawValue.localized, for: .normal)

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)

    }
    
    private func setNavigationItem(){
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: nil, title: IGStringsManager.SearchPlaceHolder.rawValue.localized)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }
    
    private func search(query: String){
        // search username in server is enable for 5 character or more than this
        if query.count < 5 || query.starts(with: "#") || !IGGlobal.matches(for: "[A-Za-z0-9]", in: query) || query.contains(" ") {
            fillResutl(searchText: query)
            return
        }
        searching = true
        latestSearchText = query
        IGClientSearchUsernameRequest.Generator.generate(query: query).successPowerful({ (responseProtoMessage, requestWrapper) in
            
            if let searchUsernameResponse = responseProtoMessage as? IGPClientSearchUsernameResponse {
                IGClientSearchUsernameRequest.Handler.interpret(response: searchUsernameResponse)
            }
            
            if let searchUsernameRequest = requestWrapper.message as? IGPClientSearchUsername {
                let search = requestWrapper.identity as! String
                if search.starts(with: "@") {
                    self.fillResutl(searchText: searchUsernameRequest.igpQuery, isUsername: true)
                } else {
                    self.fillResutl(searchText: searchUsernameRequest.igpQuery)
                }
            }
            
            self.checkSearchState()
        }).error({ (errorCode, waitTime) in
            self.checkSearchState()
        }).send()
    }
    
    /*
     * after receive search result, check latest search text with
     * current text and if is different search again with current info
     */
    private func checkSearchState(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.searching = false
            if self.latestSearchText != self.searchBar.text {
                self.search(query: self.latestSearchText)
            }
        }
    }
    
    private func fillResutl(searchText: String, isUsername: Bool = false){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.findResult = []
            let realm = try! Realm()
            
            if IGGlobal.isForwardEnable() {
                self.fillUser(realm: realm, searchText: searchText, searchDisplayName: true)
                self.fillRoom(realm: realm, searchText: searchText, searchTitle: true, isForwardEnable: true, roomType: .channel)
                self.fillRoom(realm: realm, searchText: searchText, searchTitle: true, isForwardEnable: true, roomType: .group)
            } else if isUsername {
                self.fillBot(realm: realm, searchText: searchText)
                self.fillUser(realm: realm, searchText: searchText)
                self.fillRoom(realm: realm, searchText: searchText, roomType: .channel)
                self.fillRoom(realm: realm, searchText: searchText, roomType: .group)
            } else if searchText.starts(with: "#") {
                self.fillHashtag(realm: realm, searchText: searchText)
            } else {
                self.fillBot(realm: realm, searchText: searchText, searchDisplayName: true)
                self.fillUser(realm: realm, searchText: searchText, searchDisplayName: true)
                self.fillRoom(realm: realm, searchText: searchText, searchTitle: true, roomType: .channel)
                self.fillRoom(realm: realm, searchText: searchText, searchTitle: true, roomType: .group)
                self.fillMessage(realm: realm, searchText: searchText)
                self.fillHashtag(realm: realm, searchText: searchText)
            }
            
            self.tableView.reloadData()
        }
    }
    
    private func fillRoom(realm: Realm, searchText: String, searchTitle: Bool = false, isForwardEnable: Bool = false, roomType: IGSearchType) {
        let sortProperties = [SortDescriptor(keyPath: "isParticipant", ascending: false)]
        var predicate : NSPredicate!
        if roomType == .channel {
            predicate = NSPredicate(format: "(channelRoom.publicExtra.username CONTAINS[c] %@)", searchText)
            if isForwardEnable {
                predicate = NSPredicate(format: "((channelRoom.publicExtra.username CONTAINS[c] %@) OR (title CONTAINS[c] %@)) AND typeRaw = %d AND isParticipant == true AND isReadOnly == false", searchText, searchText, IGRoom.IGType.channel.rawValue)
            } else if searchTitle {
                predicate = NSPredicate(format: "(channelRoom.publicExtra.username CONTAINS[c] %@) OR ((title CONTAINS[c] %@) AND typeRaw = %d)", searchText, searchText, IGRoom.IGType.channel.rawValue)
            }
        } else { // group
            predicate = NSPredicate(format: "(groupRoom.publicExtra.username CONTAINS[c] %@)", searchText)
            if isForwardEnable {
                predicate = NSPredicate(format: "((groupRoom.publicExtra.username CONTAINS[c] %@) OR (title CONTAINS[c] %@)) AND typeRaw = %d AND isParticipant == true AND isReadOnly == false", searchText, searchText, IGRoom.IGType.group.rawValue)
            } else if searchTitle {
                predicate = NSPredicate(format: "(groupRoom.publicExtra.username CONTAINS[c] %@) OR ((title CONTAINS[c] %@) AND typeRaw = %d)", searchText, searchText, IGRoom.IGType.group.rawValue)
            }
        }
        let rooms = realm.objects(IGRoom.self).filter(predicate).sorted(by: sortProperties)
        if rooms.count > 0 {
            self.findResult.append(IGLookAndFindStruct(type: roomType))
        }
        for room in rooms {
            self.findResult.append(IGLookAndFindStruct(room: room))
        }
    }
    
    private func fillBot(realm: Realm, searchText: String, searchDisplayName: Bool = false){
        fillUser(realm: realm, searchText: searchText, searchDisplayName: searchDisplayName, isBot: true)
    }
    
    private func fillUser(realm: Realm, searchText: String, searchDisplayName: Bool = false, isBot: Bool = false) {
        let sortProperties = [SortDescriptor(keyPath: "isInContacts", ascending: false)]
        var predicate : NSPredicate!
        if searchDisplayName {
            predicate = NSPredicate(format: "((username CONTAINS[c] %@) OR (displayName CONTAINS[c] %@)) AND (isBot == %@)", searchText, searchText, NSNumber(value: isBot))
        } else {
            predicate = NSPredicate(format: "(username CONTAINS[c] %@) AND (isBot == %@)", searchText, NSNumber(value: isBot))
        }
        
        let users = realm.objects(IGRegisteredUser.self).filter(predicate).sorted(by: sortProperties)
        if users.count > 0 {
            if isBot {
                self.findResult.append(IGLookAndFindStruct(type: .bot))
            } else {
                self.findResult.append(IGLookAndFindStruct(type: .user))
            }
        }
        for user in users {
            self.findResult.append(IGLookAndFindStruct(user: user))
        }
    }
    
    private func fillMessage(realm: Realm, searchText: String, checkHashtag: Bool = false) {
        
        var finalSearchText = searchText
        if checkHashtag && !searchText.starts(with: "#") {
            finalSearchText = "#"+finalSearchText
        }
        
        let predicate = NSPredicate(format: "roomId != %lld AND (message CONTAINS[c] %@ OR forwardedFrom.message CONTAINS[c] %@)", -1, finalSearchText, finalSearchText)
        let messages = realm.objects(IGRoomMessage.self).filter(predicate)
        if messages.count > 0 {
            if checkHashtag {
                self.findResult.append(IGLookAndFindStruct(type: .hashtag))
            } else {
                self.findResult.append(IGLookAndFindStruct(type: .message))
            }
        }
        for message in messages {
            self.findResult.append(IGLookAndFindStruct(message: message, type: .message))
        }
    }
    
    private func fillHashtag(realm: Realm, searchText: String) {
        fillMessage(realm: realm, searchText: searchText, checkHashtag: true)
    }
    
    //****************** scroll listener ******************
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
            self.view.endEditing(true)
            (searchBar.value(forKey: "cancelButton") as? UIButton)?.isEnabled = true
        }
    }
    
    //****************** SearchBar ******************
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        IGGlobal.isFromSearchPage = false

        IGRecentsTableViewController.needGetInfo = false
        self.navigationController?.popViewController(animated: false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        (searchBar.value(forKey: "cancelButton") as? UIButton)?.isEnabled = true
        if let text = searchBar.text, !text.isEmpty {
            self.search(query: text)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText.count >= 1){
            if let text = searchBar.text {
                self.search(query: text)
            }
        } else {
            DispatchQueue.main.async {
                self.findResult = []
                self.tableView.reloadData()
            }
        }
    }
    
    //****************** tableView ******************
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return findResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = self.findResult[indexPath.row]
        
        if result.isHeader {
            let cell: IGLookAndFindCell = self.tableView.dequeueReusableCell(withIdentifier: "HeaderSearch", for: indexPath) as! IGLookAndFindCell
            cell.setHeader(type: result.type)
            return cell
        }
        
        let cell: IGLookAndFindCell = self.tableView.dequeueReusableCell(withIdentifier: "LookUpSearch", for: indexPath) as! IGLookAndFindCell
        cell.setSearchResult(result: result)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 74.0, bottom: 0, right: 0)
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        IGGlobal.isFromSearchPage = true
        let searchResult = self.findResult[indexPath.row]
        
        var room = searchResult.room
        var type = IGPClientSearchUsernameResponse.IGPResult.IGPType.room.rawValue
        
        if searchResult.type == .message || searchResult.type == .hashtag {
            room = IGRoom.getRoomInfo(roomId: searchResult.message.roomId)
        } else if searchResult.type == .user {
            type = IGPClientSearchUsernameResponse.IGPResult.IGPType.user.rawValue
        }
        
        var tmpType : String = "CHAT"
        if searchResult.type == .bot || searchResult.type == .message {
            tmpType = "CHAT"
        } else if searchResult.type == .channel {
            tmpType = "CHANNEL"
        } else if  searchResult.type == .group {
            tmpType = "GROUP"
        } else {
            tmpType = "CHAT"
        }
        
        IGHelperChatOpener.manageOpenChatOrProfile(usernameType: IGPClientSearchUsernameResponse.IGPResult.IGPType(rawValue: type)!, user: searchResult.user, room: room, roomType: tmpType)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
           cell.backgroundColor = ThemeManager.currentTheme.TableViewCellColor

       }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.findResult[indexPath.row].isHeader {
            return 30.0
        }
        return 70.0
    }
}
