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
import MBProgressHUD
import IGProtoBuff

class IGSettingPrivacyAndSecurityActiveSessionsTableViewController: UITableViewController, UIGestureRecognizerDelegate {
    
    var selectedSession: IGSession?
    var currentSession: IGSession?
    var otherSessions = [IGSession]()
    var hud = MBProgressHUD()
    var numberOfRemainingSessionsToTerminate = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1.0)
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: nil, title: "SETTING_PS_ACTIVE_SESSIONS".localizedNew)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.isUserInteractionEnabled = true
        getActiveSessionList()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if otherSessions.count == 0 && currentSession == nil {
            return 0
        }
        if otherSessions.count > 0 {
            return otherSessions.count + 2
        } else {
            return otherSessions.count + 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == otherSessions.count + 1 {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let activeSessionCell = tableView.dequeueReusableCell(withIdentifier: "ActiveSessionCell", for: indexPath) as! IGSettingPrivacyAndSecurityActiveSessionsDetailTableViewCell
                if let currentlySession = currentSession {
                    activeSessionCell.setSession(currentlySession)
                    return activeSessionCell
                }
            } else if indexPath.row == 1 {
                let moreDetailsCell = tableView.dequeueReusableCell(withIdentifier: "MoreDetails", for: indexPath) as!IGSettingPrivacyAndSecurityActiveSessionMoreDetailsTableViewCell
                if let currentlySession = currentSession {
                moreDetailsCell.setSession(currentlySession)
                return moreDetailsCell
                }
            }
        } else if indexPath.section != otherSessions.count + 1  {
            if indexPath.row == 0 {
                let activeSessionCell = tableView.dequeueReusableCell(withIdentifier: "ActiveSessionCell", for: indexPath) as! IGSettingPrivacyAndSecurityActiveSessionsDetailTableViewCell
                let thisCellSession = otherSessions[indexPath.section - 1]
                activeSessionCell.setSession(thisCellSession)
                return activeSessionCell
            } else if indexPath.row == 1 {
                let moreDetailsCell = tableView.dequeueReusableCell(withIdentifier: "MoreDetails", for: indexPath) as!IGSettingPrivacyAndSecurityActiveSessionMoreDetailsTableViewCell
                moreDetailsCell.setSession(otherSessions[indexPath.section - 1])
                return moreDetailsCell
            }
        } else { //if indexPath.section == sessions.count {
            let terminateAllCell = tableView.dequeueReusableCell(withIdentifier: "TerminateAllCell", for: indexPath) as! IGSettingPrivacyAndSecurityActiveSessionTerminateAllSessionsTableViewCell
            return terminateAllCell
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 || indexPath.section != otherSessions.count + 1  {
            if indexPath.row == 0 {
                return CGFloat(80.0)
            }
        }
        return CGFloat(44.0)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == otherSessions.count + 1 {
            if otherSessions.count > 0 {
                return "SETTINGS_PS_TERMINATE_ALL_EXEPT".localizedNew
            } else {
                return nil
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var headerText = ""
        switch section {
        case 0:
            headerText = "SETTING_PS_AS_CURRENT_SESSIONS".localizedNew
        case 1:
            if otherSessions.count > 0 {
                headerText = "SETTING_PS_ACTIVE_SESSIONS".localizedNew
            } else {
                headerText = "SETTING_PS_NO_MORE_ACTIVE_SESSIONS".localizedNew
            }
        default:
            break
        }
        return headerText
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var heightOfheader : CGFloat = 36
        if section != 0 && section != otherSessions.count + 1  && section != 1 {
            heightOfheader = 3
        }
        return heightOfheader
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let containerView = view as! UITableViewHeaderFooterView

        if section == 0 {
            var headerText = ""
            switch section {
            case 0:
                headerText = "SETTING_PS_AS_CURRENT_SESSIONS".localizedNew
                containerView.textLabel?.font = UIFont.igFont(ofSize: 15)

            case 1:
                if otherSessions.count > 0 {
                    headerText = "SETTING_PS_ACTIVE_SESSIONS".localizedNew
                    containerView.textLabel?.font = UIFont.igFont(ofSize: 15)

                } else {
                    headerText = "SETTING_PS_NO_MORE_ACTIVE_SESSIONS".localizedNew
                    containerView.textLabel?.font = UIFont.igFont(ofSize: 15)

                }
            default:
                break
            }
            containerView.textLabel!.text = headerText
            containerView.textLabel?.font = UIFont.igFont(ofSize: 15)
            containerView.textLabel?.textAlignment = (containerView.textLabel?.localizedNewDirection)!
        }
        else {
            containerView.textLabel?.font = UIFont.igFont(ofSize: 15)
            containerView.textLabel?.textAlignment = (containerView.textLabel?.localizedNewDirection)!

        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if section == 0 {
            let containerView = view as! UITableViewHeaderFooterView
            if section == otherSessions.count + 1 {
                if otherSessions.count > 0 {
                    containerView.textLabel!.text = "SETTINGS_PS_TERMINATE_ALL_EXEPT".localizedNew
                } else {
                    containerView.textLabel!.text = nil
                }
            }
            containerView.textLabel?.font = UIFont.igFont(ofSize: 15)
            containerView.textLabel?.textAlignment = (containerView.textLabel?.localizedNewDirection)!
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.section != otherSessions.count + 1 {
            if indexPath.section == 0 {
                selectedSession = currentSession
            } else {
                selectedSession = otherSessions[indexPath.section - 1]
            }
            self.tableView.isUserInteractionEnabled = false
            performSegue(withIdentifier: "GoToActiveSessionDetailsPage", sender: self)
        } else {
            let logoutConfirmAlertView = UIAlertController(title: "SETTING_PS_AS_SURE_TO_TERMINATE".localizedNew, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
            let logoutAction = UIAlertAction(title: "TERMINATE".localizedNew, style:.default , handler: { _ in
                self.terminateAllSession()
            })
            let cancelAction = UIAlertAction(title: "CANCEL_BTN".localizedNew, style:.cancel , handler: { _ in
            })
            logoutConfirmAlertView.addAction(logoutAction)
            logoutConfirmAlertView.addAction(cancelAction)
            let alertActions = logoutConfirmAlertView.actions
            for action in alertActions {
                if action.title == "TERMINATE".localizedNew{
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
    }
    
    func getActiveSessionList() {
        IGGlobal.prgShow(self.view)
        IGUserSessionGetActiveListRequest.Generator.generate().success({ protoResponse in
            DispatchQueue.main.async {
                IGGlobal.prgHide()
                switch protoResponse {
                case let activeSessionListProtoResponse as IGPUserSessionGetActiveListResponse:
                     let allSessions = IGUserSessionGetActiveListRequest.Handler.interpret(response: activeSessionListProtoResponse)
                     self.otherSessions = [IGSession]()
                     for session in allSessions {
                        if session.isCurrent {
                            self.currentSession = session
                        } else {
                            self.otherSessions.append(session)
                        }
                     }
                    self.tableView.reloadData()
                default:
                    break
                }
            }
        }).error ({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                IGGlobal.prgHide()
                switch errorCode {
                case .timeout:
                    let alert = UIAlertController(title: "TIME_OUT".localizedNew, message: "MSG_PLEASE_TRY_AGAIN".localizedNew, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "GLOBAL_OK".localizedNew, style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                default:
                    break
                }
            }
        }).send()
    }
    
    func terminateAllSession() {
        if self.otherSessions.count > 0 {
            self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.hud.mode = .indeterminate
            numberOfRemainingSessionsToTerminate = self.otherSessions.count
            for session in self.otherSessions {
                self.terminateSession(sessionID : session.sessionId)
            }
        }
    }
    
    func terminateSession(sessionID : Int64) {
        IGUserSessionTerminateRequest.Generator.generate(sessionId: sessionID).success({ protoResponse in
            DispatchQueue.main.async {
                switch protoResponse {
                case let terminateSessionProtoResponse as IGPUserSessionTerminateResponse:
                    IGUserSessionTerminateRequest.Handler.interpret(response: terminateSessionProtoResponse)
                default:
                    break
                }
                self.numberOfRemainingSessionsToTerminate -= 1
                self.checkIfShouldHideHud()
            }
        }).error ({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                self.numberOfRemainingSessionsToTerminate -= 1
                self.checkIfShouldHideHud()
            }
        }).send()
    }
    
    func checkIfShouldHideHud() {
        if self.numberOfRemainingSessionsToTerminate == 0 {
            //hide hud + fetch sessions
            self.hud.hide(animated: false)
            getActiveSessionList()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         let detailOfSession = segue.destination as! IGSettingPrivacyAndSecurityActiveSessionMoreDetailsTableViewController
            detailOfSession.selectedSession = selectedSession
        
    }
}
