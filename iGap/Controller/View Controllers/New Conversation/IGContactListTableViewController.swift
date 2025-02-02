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
import Contacts
import RealmSwift
import IGProtoBuff
import MBProgressHUD
import SwiftEventBus

class IGContactListTableViewController: BaseTableViewController, UISearchResultsUpdating, IGCallFromContactListObserver {
    
    var allContacts = try! Realm().objects(IGRegisteredUser.self).filter("isInContacts == 1").sorted(byKeyPath: "displayName", ascending: true)
    var contacts : Results<IGRegisteredUser>!
    var contactSections: [Section]?
    let collation = UILocalizedIndexedCollation.current()
    var sections : [Section]!
    var forceCall: Bool = false
    var pageName : String! = IGStringsManager.NewCall.rawValue.localized
    private var lastContentOffset: CGFloat = 0
    var navigationControll : IGNavigationController!
    
    
    
    var resultSearchController : UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = ""
        searchController.searchBar.setValue(IGStringsManager.GlobalCancel.rawValue.localized, forKey: "cancelButtonText")
        
        let gradient = CAGradientLayer()
        let defaultNavigationBarFrame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.width), height: 64)

        gradient.frame = defaultNavigationBarFrame
        gradient.colors = [ThemeManager.currentTheme.NavigationFirstColor.cgColor, ThemeManager.currentTheme.NavigationSecondColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        
        searchController.searchBar.barTintColor = UIColor(patternImage: IGGlobal.image(fromLayer: gradient))
        searchController.searchBar.backgroundColor = UIColor(patternImage: IGGlobal.image(fromLayer: gradient))
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            if let searchBarCancelButton = searchController.searchBar.value(forKey: "cancelButton") as? UIButton {
                searchBarCancelButton.setTitle(IGStringsManager.GlobalCancel.rawValue.localized, for: .normal)
                searchBarCancelButton.titleLabel!.font = UIFont.igFont(ofSize: 14,weight: .bold)
                searchBarCancelButton.tintColor = UIColor.white
            }
            
            if let placeHolderInsideSearchField = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeHolderInsideSearchField.textColor = UIColor.white
                placeHolderInsideSearchField.textAlignment = .center
                placeHolderInsideSearchField.text = IGStringsManager.SearchPlaceHolder.rawValue.localized
                if let backgroundview = textField.subviews.first {
                    placeHolderInsideSearchField.center = backgroundview.center
                }
                placeHolderInsideSearchField.font = UIFont.igFont(ofSize: 15,weight: .bold)
            }
        }
        return searchController
    }()
    
    
    
    
    //header
    var headerView = UIView(frame: CGRect.init(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 150.0))
    var btnHolderView : UIView!
    
    internal static var callDelegate: IGCallFromContactListObserver!
    
    class User: NSObject {
        let registredUser: IGRegisteredUser
        @objc let name: String
        var section :Int?
        init(registredUser: IGRegisteredUser){
            self.registredUser = registredUser
            self.name = registredUser.displayName
        }
    }
    
    class Section {
        var users = [User]()
        func addUser(_ user:User){
            self.users.append(user)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contacts = allContacts
        initNavigationBar()
//        sections = fillContacts()
        
        IGContactListTableViewController.callDelegate = self
        self.tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme.TableViewCellColor
//        self.tableView.contentInset.top = 15.0
        self.tableView.sectionIndexBackgroundColor = .clear
        
        
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.searchResultsUpdater = self
        resultSearchController.obscuresBackgroundDuringPresentation = false
    }
    
    private func initNavigationBar() {
        let navigationItem = self.navigationItem as! IGNavigationItem
        var title = IGStringsManager.NewChat.rawValue.localized
        if forceCall {
            title = IGStringsManager.NewCall.rawValue.localized
        }

        navigationItem.addNavigationViewItems(rightItemText: nil, title: title)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
//        navigationItem.searchController = resultSearchController.searchBar
        
        resultSearchController.searchBar.searchBarStyle = UISearchBar.Style.minimal
        tableView.tableHeaderView = resultSearchController.searchBar
        
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }

    
    func fillContacts(searchText : String = "") {
        
        if searchText == "" {
            contacts = allContacts.sorted(byKeyPath: "displayName")
            return
        }
        
        let predicate = NSPredicate(format: "((displayName BEGINSWITH[c] %@) OR (displayName CONTAINS[c] %@)) AND (isInContacts = 1)", searchText , searchText)
        contacts = allContacts.filter(predicate).sorted(byKeyPath: "displayName")
        
        
        
        
//
//        if !searchText.isEmpty {
//            let predicate = NSPredicate(format: "((displayName BEGINSWITH[c] %@) OR (displayName CONTAINS[c] %@)) AND (isInContacts = 1)", searchText , searchText)
//            contacts = try! Realm().objects(IGRegisteredUser.self).filter(predicate)
//        } else if filterContact {
//            let predicate = NSPredicate(format: "isInContacts = 1")
//            contacts = try! Realm().objects(IGRegisteredUser.self).filter(predicate).sorted(byKeyPath: "displayName", ascending: true)
//        }
//
//        let users :[User] = contacts.map{ (registeredUser) -> User in
//            let user = User(registredUser: registeredUser )
//
//            user.section = self.collation.section(for: user, collationStringSelector: #selector(getter: User.name))
//            return user
//        }
//        var sections = [Section]()
//        for _ in 0..<self.collation.sectionIndexTitles.count{
//            sections.append(Section())
//        }
//        for user in users {
//            sections[user.section!].addUser(user)
//        }
//        for section in sections {
//            section.users = self.collation.sortedArray(from: section.users, collationStringSelector: #selector(getter: User.name)) as! [User]
//        }
//        self.contactSections = sections
//        return self.contactSections!
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
//        if (self.resultSearchController.isActive) {
//            return 1
//        } else {
//            return self.sections.count
//        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (contacts?.count ?? allContacts.count)
//        if self.resultSearchController.isActive {
//            return self.contacts.count
//        } else {
//            return self.sections[section].users.count
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contactsCell = tableView.dequeueReusableCell(withIdentifier: "ContactsCell", for: indexPath) as! IGContactTableViewCell

        contactsCell.setUser(contacts[indexPath.row])
        return contactsCell
        
//        if (self.resultSearchController.isActive) {
//            contactsCell.setUser(contacts[indexPath.row])
//        }else{
//            let user = self.sections[indexPath.section].users[indexPath.row]
//            contactsCell.setUser(user.registredUser)
//        }
//        return contactsCell
    }
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)-> String {
//        if !self.sections[section].users.isEmpty {
//            return self.collation.sectionTitles[section]
//        }
//        return ""
//    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
//    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
//        return self.collation.sectionIndexTitles
//    }
//
//    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
//        return self.collation.section(forSectionIndexTitle: index)
//    }
    
    func call(user: IGRegisteredUser,mode: String) {
        self.navigationController?.popToRootViewController(animated: true)
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).showCallPage(userId: user.id, isIncommmingCall: false , mode:mode)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
//        contacts = fillContacts(searchText: searchString)
        fillContacts(searchText: searchString)
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if resultSearchController.isActive == false {
            
            if forceCall {
                //                let user = self.sections[indexPath.section].users[indexPath.row]
                //                DispatchQueue.main.async {
                //                    (UIApplication.shared.delegate as! AppDelegate).showCallPage(userId: user.registredUser.id, isIncommmingCall: false)
                //                }
                //                return
            }
            
            IGGlobal.prgShow(self.view)
            let user = self.sections[indexPath.section].users[indexPath.row]
            IGChatGetRoomRequest.Generator.generate(peerId: user.registredUser.id).success({ (protoResponse) in
                if let chatGetRoomResponse = protoResponse as? IGPChatGetRoomResponse{
                    DispatchQueue.main.async {
                        IGGlobal.prgHide()
                        let roomId = IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                        self.navigationController?.popToRootViewController(animated: true)
                        SwiftEventBus.postToMainThread(EventBusManager.openRoom, sender: roomId)
                    }
                }
            }).error({ (errorCode, waitTime) in
                DispatchQueue.main.async {
                    IGGlobal.prgHide()

                    IGHelperAlert.shared.showCustomAlert(view: self, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.GlobalTryAgain.rawValue.localized, cancelText: IGStringsManager.GlobalOK.rawValue.localized)

                }
            }).send()
        }
    }
}

extension IGContactListTableViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
}



