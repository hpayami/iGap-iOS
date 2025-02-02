/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import RealmSwift
import Foundation
import IGProtoBuff

class IGChatRoom: Object {
    @objc dynamic  var id:     Int64               = -1
    @objc dynamic  var peer:   IGRegisteredUser?
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    convenience init(igpChatRoom: IGPChatRoom, id: Int64) {
        self.init()
        self.id = id
        
        let predicate = NSPredicate(format: "id = %lld", igpChatRoom.igpPeer.igpID)
        let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first
        
        if userInDb != nil && igpChatRoom.igpPeer.igpCacheID == userInDb?.cacheID {
            self.peer = userInDb
        } else {
            self.peer = IGRegisteredUser(igpUser: igpChatRoom.igpPeer)
        }
    }
    
    static func putOrUpdate(realm: Realm, igpChatRoom: IGPChatRoom, id: Int64) -> IGChatRoom {
        let predicate = NSPredicate(format: "id = %lld", id)
        var chatRoom: IGChatRoom! = try! Realm().objects(IGChatRoom.self).filter(predicate).first
        
        if chatRoom == nil {
            chatRoom = IGChatRoom()
            chatRoom.id = id
        }
        chatRoom.peer = IGRegisteredUser.putOrUpdate(realm: realm, igpUser: igpChatRoom.igpPeer)
        
        return chatRoom
    }
    
    //detach from current realm
    func detach() -> IGChatRoom {
        let detachedChatRoom = IGChatRoom(value: self)
        if let peer = self.peer {
            let detachedPeer = peer.detach()
            detachedChatRoom.peer = detachedPeer
        }
        return detachedChatRoom
    }
}
