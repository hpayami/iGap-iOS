//
//  DeepLinkManager.swift
//  iGap
//
//  Created by MacBook Pro on 6/25/1398 AP.
//  Copyright © 1398 AP Kianiranian STDG -www.kianiranian.com. All rights reserved.
//

import Foundation

enum DeeplinkType {
    enum Messages {
        case roomId(Id: Int64, messageId: Int64?)
        case userName(username: String?, messageId: Int64?)
    }
    
    case payment(message: String, status: PaymentStatus, orderId: String)
    case discovery(pathes: [String])
    case contact
    case profile
    case call
    case favouriteChannel(token: String?)
    case chatRoom(Messages)
    case news(showDetail: Bool? = false,id: String)
}

class DeepLinkManager {
    
    static let shared = DeepLinkManager()
    
    fileprivate init() {}
    
    private var deeplinkType: DeeplinkType?
    
    // check existing deepling and perform action
    func checkDeepLink() {
        guard let deeplinkType = deeplinkType else {
            return
        }
        DeeplinkNavigator.shared.proceedToDeeplink(deeplinkType)
        // reset deeplink after handling
        self.deeplinkType = nil // (1)
    }
    
    public func hasDeepLink() -> Bool {
        guard deeplinkType != nil else {
            return false
        }
        return true
    }
    
    @discardableResult
    func handleShortcut(item: UIApplicationShortcutItem) -> Bool {
        deeplinkType = ShortcutParser.shared.handleShortcut(item)
        return deeplinkType != nil
    }
    
    @discardableResult
    func handleDeeplink(url: URL) -> Bool {
        deeplinkType = DeepLinkParser.shared.parseDeepLink(url)
        return deeplinkType != nil
    }
    
    func handleRemoteNotification(_ notification: [AnyHashable: Any]) {
        deeplinkType = NotificationParser.shared.handleNotification(notification)
    }
}
