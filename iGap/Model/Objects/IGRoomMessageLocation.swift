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
import MapKit

class IGRoomMessageLocation: Object {
    @objc dynamic var id:         String?
    @objc dynamic var latitude:   Double      = 0.0
    @objc dynamic var longitude:  Double      = 0.0
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    convenience init(igpRoomMessageLocation: IGPRoomMessageLocation, for message: IGRoomMessage) {
        self.init()
        self.id = message.primaryKeyId
        self.latitude = igpRoomMessageLocation.igpLat
        self.longitude = igpRoomMessageLocation.igpLon
    }
    
    convenience init(location: CLLocation, for message: IGRoomMessage) {
        self.init()
        self.id = message.primaryKeyId
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageLocation: IGPRoomMessageLocation, for message: IGRoomMessage) -> IGRoomMessageLocation {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        if let locaitonInDb = realm.objects(IGRoomMessageLocation.self).filter(predicate).first {
            return locaitonInDb
        }

        let locaitonInDb = IGRoomMessageLocation()
        locaitonInDb.id = message.primaryKeyId
        locaitonInDb.latitude = igpRoomMessageLocation.igpLat
        locaitonInDb.longitude = igpRoomMessageLocation.igpLon
        
        return locaitonInDb
    }
    
    //detach from current realm
    func detach() -> IGRoomMessageLocation {
        let detachedRoomMessageLocation = IGRoomMessageLocation(value: self)
        return detachedRoomMessageLocation
    }
}
