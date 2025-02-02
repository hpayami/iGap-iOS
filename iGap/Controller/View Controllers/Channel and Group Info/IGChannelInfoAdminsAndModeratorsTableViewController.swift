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


class IGChannelInfoAdminsAndModeratorsTableViewController: BaseTableViewController{

    
    @IBOutlet weak var adminsCell: UITableViewCell!
    @IBOutlet weak var channelAdminIndicator: UIActivityIndicatorView!
    @IBOutlet weak var channelModeratorIndicator: UIActivityIndicatorView!
    @IBOutlet weak var moderatorsCell: UITableViewCell!
    @IBOutlet weak var countOfModeratorLabel: UILabel!
    @IBOutlet weak var countOfAdmins: UILabel!
    @IBOutlet weak var lblModerator: UILabel!
    @IBOutlet weak var lblAdmin: UILabel!

    var room : IGRoom?
    var hud = MBProgressHUD()
    var adminMember = [IGChannelMember]()
    var moderatorMember = [IGChannelMember]()
    var index : Int!
    var roomId: Int64!
    
    var myRole : IGChannelMember.IGRole?
    var notificationTokenModerator: NotificationToken?
    var notificationAdmin: NotificationToken?
    var adminsMembersCount : Results<IGChannelMember>!
    var moderatorsMembersCount : Results<IGChannelMember>!
    var adminsRole = IGChannelMember.IGRole.admin.rawValue
    var moderatorRole = IGChannelMember.IGRole.moderator.rawValue
    
    var predicateAdmins : NSPredicate!
    var predicateModerators : NSPredicate!

    override func viewDidLoad() {
        super.viewDidLoad()
        myRole = room?.channelRoom?.role
        roomId = room?.id
        if myRole == .admin {
            adminsCell.isHidden = true
        }
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: "DONE_BTN".localizedNew, title: "ADMINANDMODERATOR".localizedNew)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        
        predicateModerators = NSPredicate(format: "roleRaw = %d AND roomID = %lld", moderatorRole , (room?.id)!)
        moderatorsMembersCount =  try! Realm().objects(IGChannelMember.self).filter(predicateModerators!)
        predicateAdmins = NSPredicate(format: "roleRaw = %d AND roomID = %lld", adminsRole , (room?.id)!)
        adminsMembersCount =  try! Realm().objects(IGChannelMember.self).filter(predicateAdmins!)
        
        self.notificationTokenModerator = moderatorsMembersCount.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.countOfModeratorLabel.text = "\(Set(self.moderatorsMembersCount).count)"
                break
            case .update(_, _, _, _):
                self.countOfModeratorLabel.text = "\(Set(self.moderatorsMembersCount).count)"
                break
            case .error(let err):
                fatalError("\(err)")
                break
            }
        }
        self.notificationAdmin = adminsMembersCount.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.countOfAdmins.text = "\(Set(self.adminsMembersCount).count)"
                break
            case .update(_, _, _, _):
                self.countOfAdmins.text = "\(Set(self.adminsMembersCount).count)"
                break
            case .error(let err):
                fatalError("\(err)")
                break
            }
        }
    }

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        adminMember.removeAll()
        moderatorMember.removeAll()
        fetchAdminChannelMemberFromServer()
        self.tableView.isUserInteractionEnabled = true

        lblAdmin.text = "ADMIN".localizedNew
        lblModerator.text = "MODERATOR".localizedNew
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            index = 0
        }
        if indexPath.row == 1 {
            index = 1
        }
        self.tableView.isUserInteractionEnabled = false
        self.performSegue(withIdentifier: "showAdminsOrModeratorDetailTableview", sender: self)
            
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 1 && moderatorsCell.isHidden == true {
            return 0.0
        }
        if indexPath.section == 0 && indexPath.row == 0 && adminsCell.isHidden == true {
            return 0.0
        }
        return 44.0
    }
    
    func fetchAdminChannelMemberFromServer() {
        channelModeratorIndicator.startAnimating()
        channelAdminIndicator.startAnimating()
        IGChannelGetMemberListRequest.Generator.generate(roomId: roomId, offset: Int32(self.adminMember.count + self.moderatorMember.count), limit: 40, filterRole: .all).success({ (protoResponse) in
            DispatchQueue.main.async {
                switch protoResponse {
                case let getChannelMemberList as IGPChannelGetMemberListResponse:
                    let igpMembers = IGChannelGetMemberListRequest.Handler.interpret(response: getChannelMemberList, roomId: (self.room?.id)!)
                    for member in igpMembers {
                        let igmember = IGChannelMember(igpMember: member, roomId: self.roomId)
                        if member.igpRole == .admin {
                            self.adminMember.append(igmember)
                        }
                        if member.igpRole == .moderator {
                           self.moderatorMember.append(igmember)
                        }
                    }
                    self.countOfAdmins.text = "\(self.adminMember.count)"
                    self.countOfModeratorLabel.text = "\(self.moderatorMember.count)"
                    self.channelModeratorIndicator.stopAnimating()
                    self.channelAdminIndicator.stopAnimating()
                    self.channelAdminIndicator.hidesWhenStopped = true
                    self.channelModeratorIndicator.hidesWhenStopped = true
                    self.tableView.reloadData()
                    
                default:
                    break
                }
            }
        }).error ({ (errorCode, waitTime) in
            switch errorCode {
            case .timeout:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.channelModeratorIndicator.stopAnimating()
                    self.channelAdminIndicator.stopAnimating()
                    self.channelAdminIndicator.hidesWhenStopped = true
                    self.channelModeratorIndicator.hidesWhenStopped = true
                    self.present(alert, animated: true, completion: nil)
                }
            default:
                break
            }
            
        }).send()
        
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAdminsOrModeratorDetailTableview" {
            let destination = segue.destination as! IGChannelInfoAdminsListTableViewController
            destination.room = room
            switch index {
            case 0:
                destination.mode = "Admin"
                destination.allMembers = adminMember
                break
            case 1 :
                destination.mode = "Moderator"
                destination.allMembers = moderatorMember
                break
            default:
                break
            }
        }
    }
    

}
