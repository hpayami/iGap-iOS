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
import SwiftEventBus

class IGMapNearbyDistanceTableViewController: BaseTableViewController {
    
    var cellIdentifer = IGMapNearbyDistanceCell.cellReuseIdentifier()
    var nearbyDistanceList: Results<IGRealmMapNearbyDistance>!
    var notificationToken: NotificationToken?
    
    var latitude: Double!
    var longitude: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigaitonItem = self.navigationItem as! IGNavigationItem
        navigaitonItem.addNavigationViewItems(rightItemText: nil, title: IGStringsManager.Nearby.rawValue.localized)
        navigaitonItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let allNearbyUsers = IGDatabaseManager.shared.realm.objects(IGRealmMapNearbyDistance.self)
                IGDatabaseManager.shared.realm.delete(allNearbyUsers)
            }
        }
        
        nearbyDistanceList = try! Realm().objects(IGRealmMapNearbyDistance.self)
        
        self.tableView.register(IGMapNearbyDistanceCell.nib(), forCellReuseIdentifier: IGMapNearbyDistanceCell.cellReuseIdentifier())
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        self.tableView.tableHeaderView?.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        
        self.notificationToken = nearbyDistanceList!.observe { (changes: RealmCollectionChange) in
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
        if IGAppManager.sharedManager.isUserLoggiedIn() {
            self.fetchNearbyUsersDistanceList()
        } else {
            SwiftEventBus.on(self, name: EventBusManager.login, queue: OperationQueue.current) { [weak self] (result) in
                self?.fetchNearbyUsersDistanceList()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.isUserInteractionEnabled = true
    }
    
    
    private func fetchNearbyUsersDistanceList() {
        IGGeoGetNearbyDistance.Generator.generate(lat: latitude, lon: longitude).success { (responseProtoMessage) in
            DispatchQueue.main.async {
                if let nearbyDistanceResponse = responseProtoMessage as? IGPGeoGetNearbyDistanceResponse {
                    IGGeoGetNearbyDistance.Handler.interpret(response: nearbyDistanceResponse)
                }
            }}.error({ (errorCode, waitTime) in }).send()
    }
    
    func manageOpenChat(userId: Int64){
        let realm = try! Realm()
        let predicate = NSPredicate(format: "chatRoom.peer.id = %lld", userId)
        if let roomInfo = realm.objects(IGRoom.self).filter(predicate).first {
            openChat(roomInfo: roomInfo)
        } else {
            IGChatGetRoomRequest.Generator.generate(peerId: userId).success({ (protoResponse) in
                DispatchQueue.main.async {
                    if let chatGetRoomResponse = protoResponse as? IGPChatGetRoomResponse {
                        IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                        self.openChat(roomInfo: IGRoom(igpRoom: chatGetRoomResponse.igpRoom))
                    }
                }
            }).error({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    break
                default:
                    break
                }
                
            }).send()
        }
    }
    
    func openChat(roomInfo: IGRoom){
        let roomVC = IGMessageViewController.instantiateFromAppStroryboard(appStoryboard: .Main)
        roomVC.room = roomInfo
        roomVC.hidesBottomBarWhenPushed = true
        self.navigationController!.pushViewController(roomVC, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyDistanceList!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifer) as! IGMapNearbyDistanceCell
        cell.setUserInfo(nearbyDistance : nearbyDistanceList![indexPath.row])
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 82.0, bottom: 0, right: 0)
        cell.layoutMargins = UIEdgeInsets.zero

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.isUserInteractionEnabled = false
        manageOpenChat(userId: nearbyDistanceList![indexPath.row].id)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78.0
    }
}



