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
import IGProtoBuff
import SwiftProtobuf
import SwiftEventBus

fileprivate class IGFactoryTask: NSObject {
    enum Status {
        case pending
        case executing
        case finished
        case failed
    }
    var task:       ()->()
    var success:    (()->())?
    var error:      (()->())?
    var status:     Status      = .pending
    var randomID:   String      = ""
    var isUpdateStatusRunning : Bool = false
    override init() {
        self.task = {}
        self.randomID = IGGlobal.randomString(length: 64)
        super.init()
    }
    
    init(task: @escaping ()->()) {
        self.task = task
    }
    
    //MARK: Dependencies
    convenience init(dependencyUserTask userID: Int64?, cacheID: String?) {
        self.init()
        let task = {
            if let id = userID, id != 0 {
                var isUserInfoInDatabaseValid = false
                let predicate = NSPredicate(format: "id = %lld", id)
                if let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                    if let cID = cacheID, cID != "" {
                        if userInDb.cacheID == cID {
                            isUserInfoInDatabaseValid = true
                        }
                    } else {
                        //if no cache id is provided, assume that user info is in sync with server
                        isUserInfoInDatabaseValid = true
                    }
                }
                if isUserInfoInDatabaseValid {
                    self.success!()
                } else {
                    IGUserInfoRequest.Generator.generate(userID: id).success({ (responseProtoMessage) in
                        IGDatabaseManager.shared.perfrmOnDatabaseThread {
                            switch responseProtoMessage {
                            case let response as IGPUserInfoResponse:
                                let user = IGRegisteredUser(igpUser: response.igpUser)
                                try! IGDatabaseManager.shared.realm.write {
                                    IGDatabaseManager.shared.realm.add(user, update: .modified)
                                }
                            default:
                                break
                            }
                            IGFactory.shared.performInFactoryQueue {
                                self.success!()
                            }
                        }
                    }).error({ (errorCode, waitTime) in
                        DispatchQueue.main.async {
                            self.error!()
                        }
                    }).send()
                }
            } else {
                self.success!()
            }
        }
        self.task = task
    }
    
    convenience init(dependencyRoomTask roomID: Int64?, isParticipane: Bool) {
        self.init()
        let task = {
            //TODO: complete this
            if let id = roomID, id != 0 {
                IGDatabaseManager.shared.perfrmOnDatabaseThread {
                    let predicate = NSPredicate(format: "id = %lld", id)
                    if let roomInDb = try! Realm().objects(IGRoom.self).filter(predicate).first {
                        if roomInDb.isParticipant != isParticipane { // if roomInDb.isParticipant == true {
                            try! IGDatabaseManager.shared.realm.write {
                                roomInDb.isParticipant = isParticipane
                            }
                        }
                        IGFactory.shared.performInFactoryQueue {
                            self.success!()
                        }
                    } else {
                        //fetch room info
                        IGClientGetRoomRequest.Generator.generate(roomId: id).success({ (responseProto) in
                            IGDatabaseManager.shared.perfrmOnDatabaseThread {
                                switch responseProto {
                                case let response as IGPClientGetRoomResponse:
                                    let igpRoom = response.igpRoom
                                    try! IGDatabaseManager.shared.realm.write {
                                        let room = IGRoom.putOrUpdate(igpRoom)
                                        room.isParticipant = isParticipane
                                        IGDatabaseManager.shared.realm.add(room, update: .modified)
                                    }
                                default:
                                    break
                                }
                                IGFactory.shared.performInFactoryQueue {
                                    self.success!()
                                }
                            }
                            
                        }).error({ (errorCode, waitTime) in
                            self.error!()
                        }).send()
                    }
                }
            } else {
                self.success!()
            }
        }
        self.task = task
    }
    
    //MARK: Public Setters
    func success(_ success: @escaping ()->()) -> IGFactoryTask {
        self.success = success
        return self
    }
    
    func error(_ error: @escaping ()->()) -> IGFactoryTask {
        self.error = error
        return self
    }
    
    func execute() {
        self.task()
    }
    
    @discardableResult
    func addToQueue(hightPriority: Bool = false) -> IGFactoryTask {
        IGFactory.shared.addToFactoryQueue(task: self, hightPriority: hightPriority)
        return self
    }
}

//MARK: -
class IGFactory: NSObject {
    static let shared = IGFactory()
    
    fileprivate var factoryQueue:  DispatchQueue
    fileprivate var tasks  = [IGFactoryTask]()
    var userIdsToFetchInfo = [Int64]()
    var userIdsFetchInfoCompletionBlock: (()->())?
    
    
    private override init() {
        factoryQueue  = DispatchQueue.main //(label: "im.igap.ios.queue.factory.main")
        super.init()
    }
    
    
    fileprivate func addToFactoryQueue(task: IGFactoryTask, hightPriority: Bool) {
        performInFactoryQueue {
            if hightPriority {
                if self.tasks.count > 0 {
                    self.tasks.insert(task, at: 0)
                } else {
                    self.tasks.append(task)
                }
            } else {
                self.tasks.append(task)
            }
        }
    }
    
    private func performNextFactoryTaskIfPossible () {
        performInFactoryQueue {
            if let task = self.tasks.first {
                if task.status == .pending {
                    task.status = .executing
                    task.execute()
                }
            }
        }
        /*
        performInFactoryQueue {
            if let task = self.tasks.first {
                if task.status == .pending {
                    task.status = .executing
                    task.execute()
                } else {
                    print ("✪ task thread is already busy")
                }
            } else {
                print ("✔︎ no more tasks in queue")
            }
        }
        */
    }
    
    private func removeTaskFromQueueAndPerformNext(_ task: IGFactoryTask) {
        performInFactoryQueue {
            if let index = self.tasks.firstIndex(of: task) {
                self.tasks.remove(at: index)
                self.performNextFactoryTaskIfPossible()
            }
        }
    }
    
    fileprivate func performInFactoryQueue(task: @escaping ()->()) {
        factoryQueue.async {
            task()
        }
    }
    
    //let task = getFactoryTask()
    fileprivate func getFactoryTask() -> IGFactoryTask? {
        return nil//IGFactoryTask()
    }
    
    //self.setFactoryTaskSuccess(task: task)
    fileprivate func setFactoryTaskSuccess(task: IGFactoryTask?) {
        if task == nil {return}
        task!.success!()
    }
    
    //self.setFactoryTaskError(task: task)
    fileprivate func setFactoryTaskError(task: IGFactoryTask?) {
        if task == nil {return}
        task!.error!()
    }
    
    //self.doFactoryTask(task: task)
    fileprivate func doFactoryTask(task: IGFactoryTask?){
        if task == nil {return}
        
        task!.success ({
            self.removeTaskFromQueueAndPerformNext(task!)
        }).error ({
            self.removeTaskFromQueueAndPerformNext(task!)
        }).addToQueue()
        self.performNextFactoryTaskIfPossible()
    }
    
    //self.doFactoryTaskWithoutPerform(task: task)
    fileprivate func doFactoryTaskWithoutPerform(task: IGFactoryTask?){
        if task == nil {return}
        
        task!.success ({
            self.removeTaskFromQueueAndPerformNext(task!)
        }).error ({
            self.removeTaskFromQueueAndPerformNext(task!)
        }).addToQueue()
    }
    
    //self.doFactoryTaskList(tasks: tasks)
    fileprivate func doFactoryTaskList(tasks: [IGFactoryTask?]){
        for task in tasks {
            doFactoryTaskWithoutPerform(task: task)
        }
        self.performNextFactoryTaskIfPossible()
    }
    
    //MARK: ▶︎▶︎ Client Search Username
    func saveSearchUsernameResult(_ searchUsernameResult: [IGPClientSearchUsernameResponse.IGPResult] ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                for searchUsername in searchUsernameResult {
                    
                    var predicate: NSPredicate!
                    
                    if searchUsername.igpType.rawValue == IGPClientSearchUsernameResponse.IGPResult.IGPType.room.rawValue {
                        predicate = NSPredicate(format: "room.id = %lld", searchUsername.igpRoom.igpID)
                    } else {
                        predicate = NSPredicate(format: "user.id = %lld", searchUsername.igpUser.igpID)
                    }
                    
                    if let searchResult = IGDatabaseManager.shared.realm.objects(IGRealmClientSearchUsername.self).filter(predicate).first {
                        searchResult.room = searchResult.setRoom(room: searchUsername.igpRoom)
                        searchResult.user = searchResult.setUser(user: searchUsername.igpUser)
                        searchResult.type = searchUsername.igpType.rawValue
                    } else {
                        IGDatabaseManager.shared.realm.add(IGRealmClientSearchUsername(searchUsernameResult: searchUsername))
                    }
                    
                }
            }
        }
    }
    
    func updateIgpMessagesToDatabase(_ igpMessage: IGPRoomMessage, primaryKeyId: String, roomId: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let message = IGRoomMessage.putOrUpdate(igpMessage: igpMessage, roomId: roomId) {
                    //message.primaryKeyId = primaryKeyId
                    /*
                     if igpMessage.igpAdditionalType == AdditionalType.STICKER.rawValue {
                     message.type = .sticker
                     }
                     */
                    IGDatabaseManager.shared.realm.add(message, update: .modified)
                    
                    self.updateRoomLastMessageIfPossible(roomID: roomId)
                }
            }
        }
    }
    
    func saveNewlyWriitenMessageToDatabase(_ message: IGRoomMessage) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.add(message, update: .modified)
                let roomId = message.roomId
                self.updateRoomLastMessageIfPossibleWithoutTransaction(roomID: roomId)
            }
        }
    }
    
    func saveForwardMessage(roomId: Int64, messageId: Int64, isFromCloud: Bool = false, completion: @escaping (_ message: IGRoomMessage) -> Void) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            guard let forwardMessage = IGRoomMessage.getMessageWithId(messageId: messageId) else {
                return
            }
            var message: IGRoomMessage!
            if isFromCloud && forwardMessage.forwardedFrom == nil {
                message = IGRoomMessage(value: forwardMessage)
                message.creationTime = Date()
                message.status = IGRoomMessageStatus.sending
                message.temporaryId = IGGlobal.randomString(length: 64)
                message.primaryKeyId = IGGlobal.randomString(length: 64)
                let fakeId = IGGlobal.fakeMessageId()
                message.randomId = fakeId
                message.id = fakeId
            } else {
                message = IGRoomMessage(body: "")
                message.type = .text
                message.roomId = roomId
                message.forwardedFrom = forwardMessage
            }
            if message != nil {
                try! IGDatabaseManager.shared.realm.write {
                    IGDatabaseManager.shared.realm.add(message, update: .modified)
                    self.updateRoomLastMessageIfPossibleWithoutTransaction(roomID: roomId)
                }
                completion(message)
            }
        }
    }
    
    func updateRoomLastMessageIfPossible(roomID: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomID)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                var shouldIncreamentUnreadCount = true
                var lastMessage: IGRoomMessage?
                let messagePredicate = NSPredicate(format: "roomId = %lld AND isDeleted == false", roomID)
                
                if let lastMessageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(messagePredicate).sorted(byKeyPath: "creationTime").last {
                    if let authorHash = lastMessageInDb.authorHash {
                        if authorHash == IGAppManager.sharedManager.authorHash() {
                            shouldIncreamentUnreadCount = false
                        }
                    }
                    
                    if roomInDb.lastMessage?.id == lastMessageInDb.id || lastMessageInDb.isInvalidated {
                        return
                    }
                    lastMessage = lastMessageInDb
                } else {
                    //room has no message
                    shouldIncreamentUnreadCount = false
                }
                
                try! IGDatabaseManager.shared.realm.write {
                    if shouldIncreamentUnreadCount {
                        let unreadCount = roomInDb.unreadCount + 1
                        if !AppDelegate.appIsInBackground {
                            roomInDb.badgeUnreadCount = unreadCount
                        }
                        roomInDb.unreadCount = unreadCount
                    }
                    roomInDb.lastMessage = lastMessage
                    if let messageTime = lastMessage?.creationTime?.timeIntervalSinceReferenceDate {
                        roomInDb.sortimgTimestamp = messageTime
                    }
                }
            }
        }
    }
    
    func updateRoomLastMessageIfPossibleWithoutTransaction(roomID: Int64) {
        let predicate = NSPredicate(format: "id = %lld", roomID)
        if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
            var shouldIncreamentUnreadCount = true
            var lastMessage: IGRoomMessage?
            let messagePredicate = NSPredicate(format: "roomId = %lld AND isDeleted == false", roomID)
            
            if let lastMessageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(messagePredicate).sorted(byKeyPath: "creationTime").last {
                if let authorHash = lastMessageInDb.authorHash {
                    if authorHash == IGAppManager.sharedManager.authorHash() {
                        shouldIncreamentUnreadCount = false
                    }
                }
                
                if roomInDb.lastMessage?.id == lastMessageInDb.id || lastMessageInDb.isInvalidated {
                    return
                }
                lastMessage = lastMessageInDb
            } else {
                //room has no message
                shouldIncreamentUnreadCount = false
            }
            
            if shouldIncreamentUnreadCount {
                let unreadCount = roomInDb.unreadCount + 1
                if !AppDelegate.appIsInBackground {
                    roomInDb.badgeUnreadCount = unreadCount
                }
                roomInDb.unreadCount = unreadCount
            }
            roomInDb.lastMessage = lastMessage
            if let messageTime = lastMessage?.creationTime?.timeIntervalSinceReferenceDate {
                roomInDb.sortimgTimestamp = messageTime
            }
        }
    }
    
    func updateSendingMessageStatus(_ temporaryMessageInDb: IGRoomMessage, with igpMessageFromServer: IGPRoomMessage) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            if let message = IGRoomMessage.putOrUpdate(igpMessage: igpMessageFromServer, roomId: temporaryMessageInDb.roomId) {
                if let tempId = temporaryMessageInDb.temporaryId {
                    let predicate = NSPredicate(format: "temporaryId = %@", tempId)
                    if let tempMessageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                        message.primaryKeyId = tempMessageInDb.primaryKeyId
                        try! IGDatabaseManager.shared.realm.write {
                            IGDatabaseManager.shared.realm.add(message, update: .modified)
                        }
                    }
                }
                let roomId = message.roomId
                self.updateRoomLastMessageIfPossible(roomID: roomId)
            }
        }
    }
    
    func updateMessageStatus(primaryKeyId: String, status: IGRoomMessageStatus, hasAttachment: Bool = false) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            var predicate: NSPredicate!
            
            if hasAttachment {
                predicate = NSPredicate(format: "attachment.cacheID = %@", primaryKeyId)
            } else {
                predicate = NSPredicate(format: "primaryKeyId = %@", primaryKeyId)
            }
            
            try! IGDatabaseManager.shared.realm.write {
                if let message = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                    message.status = status
                }
            }
            
        }
    }
    
    func updateMessageStatusToFail(message: IGRoomMessage, primaryKey: String? = nil) {
        // fetch 'primaryKey' out of 'perfrmOnDatabaseThread' for avoid from 'Realm accessed from incorrect thread' crash
        var messagePrimaryKey = primaryKey
        if messagePrimaryKey == nil {
            messagePrimaryKey = message.primaryKeyId
        }
        
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "primaryKeyId = %@", messagePrimaryKey!)
            if let messageUpdate = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    messageUpdate.status = IGRoomMessageStatus.failed
                }
                SwiftEventBus.postToMainThread("\(IGGlobal.eventBusChatKey)\(messageUpdate.roomId)", sender: (action: ChatMessageAction.locallyUpdateStatus, localMessage: message))
            }
        }
    }
    
    //for an already sent message (sent -> delivered -> seen)
    func updateMessageStatus(_ messageID: Int64, roomID: Int64, status: IGPRoomMessageStatus, statusVersion: Int64, updaterAuthorHash: String, response: IGPResponse) {
        if IGAppManager.sharedManager.authorHash() == updaterAuthorHash && status == .seen {
            markAllMessagesAsRead(roomId: roomID, clearId: messageID)
        }
        
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %lld AND roomId = %lld",messageID, roomID)
                if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                    
                    if IGRoomMessageStatus.fetchIGValue(messageInDb.status) > IGRoomMessageStatus.fetchIGPValue(status) { // don't write a status with lower level. e.g. when status is 'seen' don't write 'delivered'
                        return
                    }
                    
                    switch status {
                    case .delivered:
                        messageInDb.status = .delivered
                    case .sending:
                        messageInDb.status = .sending
                    case .sent:
                        messageInDb.status = .sent
                    case .seen:
                        messageInDb.status = .seen
                    case .failed:
                        messageInDb.status = .failed
                    case .listened:
                        messageInDb.status = .listened
                    default:
                        break
                    }
                    messageInDb.statusVersion = statusVersion
                    
                    SwiftEventBus.postToMainThread("\(IGGlobal.eventBusChatKey)\(messageInDb.roomId)", sender: (action: ChatMessageAction.updateStatus, messageId: messageID))
                }
            }
        }
    }
    
    func editMessage(_ messageID: Int64, roomID: Int64, message: String, messageType: IGPRoomMessageType, messageVersion: Int64, oldMessage: IGRoomMessage? = nil) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld AND roomId = %lld",messageID, roomID)
            if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    messageInDb.isEdited = true
                    messageInDb.message = message
                    messageInDb.type = IGRoomMessageType.unknown.fromIGP(messageType)
                    messageInDb.messageVersion = messageVersion
                    messageInDb.linkInfo = ActiveLabelJsonify.toJson(message)
                }
                SwiftEventBus.postToMainThread("\(IGGlobal.eventBusChatKey)\(messageInDb.roomId)", sender: (action: ChatMessageAction.edit, messageId: messageID, roomId: roomID, message: message, messageType: messageType, messageVersion: messageVersion))
            }
        }
    }
    
    func setMessageDeleted(_ messageID: Int64, roomID: Int64, deleteVersion: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld AND roomId = %lld",messageID, roomID)
            let lastRealMessage = IGRoomMessage.getLastMessage(roomId: roomID, isDeleted: false)
            let deletedMessage = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first
            if deletedMessage != nil {
                try! IGDatabaseManager.shared.realm.write {
                    deletedMessage!.isDeleted = true
                    deletedMessage!.deleteVersion = deleteVersion
                }
                if let lastMessageId = lastRealMessage?.id, deletedMessage!.id >= lastMessageId { // last message is deleted
                    IGRoom.setLastMessage(roomId: roomID, isDeleted: false)
                }
            }
            SwiftEventBus.postToMainThread("\(IGGlobal.eventBusChatKey)\(roomID)", sender: (action: ChatMessageAction.delete, roomId: roomID, messageId: messageID))
        }
    }
    
    func deleteMessageWithPrimaryKeyId(primaryKeyId: String?, hasAttachment: Bool = false) {
        if primaryKeyId == nil {
            return
        }
        
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            var predicate: NSPredicate!
            if hasAttachment {
                predicate = NSPredicate(format: "attachment.cacheID = %@", primaryKeyId!)
            } else {
                predicate = NSPredicate(format: "primaryKeyId = %@", primaryKeyId!)
            }
            if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    IGDatabaseManager.shared.realm.delete(messageInDb)
                }
            }
        }
    }
    
    func deleteAllMessages(roomId: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "roomId = %lld", roomId)
            let messages = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate)
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.delete(messages)
            }
        }
    }

    func setClearMessageHistory(_ roomID : Int64, clearID: Int64 ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            
            try! IGDatabaseManager.shared.realm.write {
                let roomPredicate = NSPredicate(format: "id = %lld", roomID)
                if  let room = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(roomPredicate).first {
                    if clearID == 0 || room.lastMessage == nil || (room.lastMessage?.id)! <= clearID {
                        room.clearId = clearID
                        room.lastMessage = nil
                    }
                    
                    //Query Explain: delete all messageId that is lower than clearId OR message status raw value is lower than 'sent' status (this means message is unknown, failed or sending)
                    let messagePredicate = NSPredicate(format: "roomId = %lld AND (id <= %lld OR statusRaw < %d) ", roomID, clearID, IGRoomMessageStatus.sent.rawValue)
                    IGDatabaseManager.shared.realm.delete(IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(messagePredicate))
                }
            }
        }
    }
    
    //TODO: merge with leftRoomInDatabase
    func setDeleteRoom(roomID : Int64){
        //IGFactory.shared.deleteShareInfo(id: roomID, isContact: false)
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld",roomID)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.isParticipant = false
                }
            }
        }
    }

    func setMessageNeedsToFetchBefore(_ state: Bool, messageId: Int64, roomId : Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld AND roomId = %lld", messageId, roomId)
            if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    messageInDb.shouldFetchBefore = state
                }
            }
        }
    }
    
    func setMessageIsLastMesssageInRoom(messageId: Int64, roomId : Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld AND roomId = %lld", messageId, roomId)
            if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    messageInDb.isLastMessage = true
                    messageInDb.shouldFetchBefore = false
                }
            }
        }
    }
    
    //MARK: --------------------------------------------------------
    //MARK: ▶︎▶︎ User
    func updateUserStatus(_ userId: Int64, status: IGRegisteredUser.IGLastSeenStatus) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {

            let predicate = NSPredicate(format: "id = %lld", userId)
            if let userInDb = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    userInDb.lastSeenStatus = status
                    userInDb.lastSeen = Date()
                }
            }
        }
    }

    /* set "isInContacts" to false when "isDeleted" is true */
    func clearExtraContacts(){
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                try! Realm().objects(IGRegisteredUser.self).filter("isDeleted == 1").setValue(false, forKey: "isInContacts")
            }
        }
    }

    func markContactsAsDeleted(){
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter("isDeleted == false").setValue(true, forKey: "isDeleted")
            }
        }
    }

    func saveContactsToDatabase(_ contacts:[IGContact]) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            for contact in contacts {
                try! IGDatabaseManager.shared.realm.write {
                    IGDatabaseManager.shared.realm.add(contact, update: .modified)
                }
            }
        }
    }

    func contactDelete(phone: Int64) {
        let predicate = NSPredicate(format: "phone == %lld", phone)
        if let contact = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
            //IGFactory.shared.deleteShareInfo(id: contact.id)
        }

        IGDatabaseManager.shared.perfrmOnDatabaseThread {

            try! IGDatabaseManager.shared.realm.write {

                let predicate = NSPredicate(format: "phone == %lld", phone)
                if let contact = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                    contact.isInContacts = false
                    contact.phone = 0
                }
            }
        }
    }

    func contactEdit(contactEditInfo: IGPUserContactsEditResponse) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "phone == %lld", contactEditInfo.igpPhone)
                if let contact = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                    contact.firstName = contactEditInfo.igpFirstName
                    contact.lastName = contactEditInfo.igpLastName
                    contact.displayName = contactEditInfo.igpFirstName + " " + contactEditInfo.igpLastName
                    contact.initials = contactEditInfo.igpInitials

                    /**
                     * set data to 'IGRoom' for run 'RealmCollectionChange' and update room title in view
                     **/
                    let predicateRoom = NSPredicate(format: "chatRoom.peer.id == %lld", contact.id)
                    if let room = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicateRoom).first {
                        room.title = contactEditInfo.igpFirstName + " " + contactEditInfo.igpLastName
                    }
                }
            }
        }
    }


    //TODO: merge with setDeleteRoom
    func leftRoomInDatabase(roomID: Int64, memberId: Int64) {
        //IGFactory.shared.deleteShareInfo(id: roomID, isContact: false)
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            if IGAppManager.sharedManager.userID() == memberId {
                self.deleteAllMessages(roomId: roomID)
                let predicate = NSPredicate(format: "id = %lld", roomID)
                if let roomInDb = try! Realm().objects(IGRoom.self).filter(predicate).first {
                    try! IGDatabaseManager.shared.realm.write {
                        roomInDb.isParticipant = false
                    }
                }
            }
        }
    }

    func addRegistredContacts(_ igpContacts: [IGPUserContactsImportResponse.IGPContact]) {
        for igpContact in igpContacts {
            let registredUserID = igpContact.igpUserID
            IGFactoryTask.init(dependencyUserTask: registredUserID, cacheID: nil).success ({
                IGDatabaseManager.shared.perfrmOnDatabaseThread {

                    let predicate = NSPredicate(format: "id = %lld", registredUserID)
                    if let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                        let phone = igpContact.igpClientID
                        let cotactPredicate = NSPredicate(format: "phoneNumber = %@", phone)
                        if let contactInDB = try! Realm().objects(IGContact.self).filter(cotactPredicate).first {
                            try! IGDatabaseManager.shared.realm.write {
                                contactInDB.user = userInDb
                            }
                        }
                    }
                }
            }).error ({
                //self.setFactoryTaskError(task: task)
            }).execute()
        }
    }

    func saveRegistredContactsUsers(_ igpRegistredUsers: [IGPRegisteredUser]) {
        var delay = 0.0
        var savedCount: Double = 0.0
        let registredUsersArray = igpRegistredUsers.chunks(25)
        if registredUsersArray.count == 0 {
            IGContactManager.sharedManager.contactExchangeLevel.accept(.completed)
            return
        }
        for registredUsers in registredUsersArray {
            delay += 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                for userInfo in registredUsers {
                    IGDatabaseManager.shared.perfrmOnDatabaseThread {
                        try! IGDatabaseManager.shared.realm.write {
                            let registeredUser = IGRegisteredUser.putOrUpdate(realm: IGDatabaseManager.shared.realm, igpUser: userInfo)
                            registeredUser.isInContacts = true
                            IGDatabaseManager.shared.realm.add(registeredUser, update: .modified)
                            //IGDatabaseManager.shared.realm.add(IGHelperGetShareData.setRealmShareInfo(igpUser: igpRegistredUser, igUser: user), update: .modified)
                        }
                    }
                    savedCount = savedCount + 1
                }
                
                let percent = savedCount / Double(igpRegistredUsers.count) * 100
                IGContactManager.sharedManager.contactExchangeLevel.accept(.gettingList(percent: percent))
                
                if Int(savedCount) == igpRegistredUsers.count { //after add all contacts to db do contact clearization
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // use from delay just for show "%100" to user
                        IGContactManager.sharedManager.contactExchangeLevel.accept(.completed)
                    }
                    self.clearExtraContacts()
                }
            }
        }
    }

    func saveRegistredUsers(_ igpRegistredUsers: [IGPRegisteredUser]) {
        for igpRegistredUser in igpRegistredUsers {
            IGDatabaseManager.shared.perfrmOnDatabaseThread {
                try! IGDatabaseManager.shared.realm.write {
                    let user = IGRegisteredUser(igpUser: igpRegistredUser)
                    IGDatabaseManager.shared.realm.add(user, update: .modified)
                    let predicate = NSPredicate(format: "id = %lld", user.id)
                    if let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                        let cotactPredicate = NSPredicate(format: "phoneNumber = %@", "\(user.phone)")
                        if let contactInDB = try! Realm().objects(IGContact.self).filter(cotactPredicate).first {
                            contactInDB.user = userInDb
                        }
                    }
                }
            }
        }
    }

    func updateUserInfoExpired(_ userId: Int64) {
        IGFactoryTask(dependencyUserTask: userId, cacheID: nil).success ({
            IGDatabaseManager.shared.perfrmOnDatabaseThread ({
                let predicate = NSPredicate(format: "id = %lld", userId)
                if let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                    try! IGDatabaseManager.shared.realm.write {
                        if userInDb.lastSeenStatus == .online {
                            self.updateUserStatus(userId, status: .longTimeAgo)
                        } else if userInDb.lastSeenStatus == .longTimeAgo {
                            self.updateUserStatus(userId, status: .online)

                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kIGNoticationForPushUserExpire),
                                                        object: nil,
                                                        userInfo: ["user": userId])
                    }
                }
            })
        }).error ({
            //self.setFactoryTaskError(task: task)
        }).execute()
    }

    func saveBlockedUsers(_ blockedUsers : [IGPUserContactsGetBlockedListResponse.IGPUser]){
        for blockedUser in blockedUsers {
            IGFactoryTask(dependencyUserTask: blockedUser.igpUserID, cacheID: nil).success ({
                IGDatabaseManager.shared.perfrmOnDatabaseThread ({

                    let predicate = NSPredicate(format: "id = %lld", blockedUser.igpUserID)
                    if let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                        try! IGDatabaseManager.shared.realm.write {
                            userInDb.isBlocked = true
                        }
                    }
                })
            }).error ({
                //self.setFactoryTaskError(task: task)
            }).execute()
        }
    }

    func updateBlockedUser(_ blockedUserId: Int64, blocked: Bool ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", blockedUserId)
            try! IGDatabaseManager.shared.realm.write {
                if let userInDb = try! Realm().objects(IGRegisteredUser.self).filter(predicate).first {
                    userInDb.isBlocked = blocked
                }
            }
        }
    }

    func updateUserNickname(_ userId: Int64, nickname: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", userId)
            if let userInDb = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    userInDb.displayName = nickname
                }
            }
        }
    }

    func updateUserEmail(_ userId: Int64, email: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", userId)
            if let userInDb = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    userInDb.email = email
                }
            }
        }
    }

    func updateProfileUsername(_ userID: Int64, username: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", userID)
            if let userInDb = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    userInDb.username = username
                }
            }
        }
    }

    func updateUserSelfRemove(_ userId: Int64, selfRemove:Int32) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", userId)
            if let userInDb = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    userInDb.selfRemove = selfRemove
                }
            }
        }
    }

    func updateProfileGender(_ userId: Int64 , igpGender: IGPGender) {
        IGFactoryTask(dependencyUserTask: userId, cacheID: nil).success({
            IGDatabaseManager.shared.perfrmOnDatabaseThread {
                var gender: IGGender
                switch igpGender {
                case .male:
                    gender = .male
                case .female:
                    gender = .female
                case .unknown :
                    gender = .unknown
                default:
                    gender = .male
                }
                try! IGDatabaseManager.shared.realm.write {
                    if let sessionInfo = IGDatabaseManager.shared.realm.objects(IGSessionInfo.self).first {
                        sessionInfo.gender = gender
                    }
                }
            }
        }).error ({
            //self.setFactoryTaskError(task: task)
        }).execute()
    }

    func updateUserPrivacy(_ igPrivacyType: IGPrivacyType , igPrivacyLevel: IGPrivacyLevel) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let userPrivacyInDb = IGDatabaseManager.shared.realm.objects(IGUserPrivacy.self).first {
                    switch igPrivacyType {
                    case .avatar:
                        userPrivacyInDb.avatar = igPrivacyLevel
                    case .channelInvite:
                        userPrivacyInDb.channelInvite = igPrivacyLevel
                    case .groupInvite:
                        userPrivacyInDb.groupInvite = igPrivacyLevel
                    case .userStatus:
                        userPrivacyInDb.userStatus = igPrivacyLevel
                    case .voiceCalling:
                        userPrivacyInDb.voiceCalling = igPrivacyLevel
                    case .videoCalling:
                        userPrivacyInDb.videoCalling = igPrivacyLevel
                    case .screenSharing:
                        userPrivacyInDb.screenSharing = igPrivacyLevel
                    case .secretChat:
                        userPrivacyInDb.secretChat = igPrivacyLevel
                    }
                } else {
                    let userPrivacy = IGUserPrivacy()
                    switch igPrivacyType {
                    case .avatar:
                        userPrivacy.avatar = igPrivacyLevel
                    case .channelInvite:
                        userPrivacy.channelInvite = igPrivacyLevel
                    case .groupInvite:
                        userPrivacy.groupInvite = igPrivacyLevel
                    case .userStatus:
                        userPrivacy.userStatus = igPrivacyLevel
                    case .voiceCalling:
                        userPrivacy.voiceCalling = igPrivacyLevel
                    case .videoCalling:
                        userPrivacy.videoCalling = igPrivacyLevel
                    case .screenSharing:
                        userPrivacy.screenSharing = igPrivacyLevel
                    case .secretChat:
                        userPrivacy.secretChat = igPrivacyLevel
                    }
                    IGDatabaseManager.shared.realm.add(userPrivacy, update: .modified)
                }
            }
        }
    }

    func updateBio(bio: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", IGAppManager.sharedManager.userID()!)
            try! IGDatabaseManager.shared.realm.write {
                if let userRegister = IGDatabaseManager.shared.realm.objects(IGRegisteredUser.self).filter(predicate).first {
                    userRegister.bio = bio
                }
            }
        }
    }

    func setSignalingConfiguration(configuration: IGPSignalingGetConfigurationResponse) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let signaling = IGDatabaseManager.shared.realm.objects(IGSignaling.self).first {
                    signaling.voiceCalling = configuration.igpVoiceCalling
                    signaling.videoCalling = configuration.igpVideoCalling
                    signaling.secretChat = configuration.igpSecretChat
                    signaling.screenSharing = configuration.igpScreenSharing

                    signaling.iceServer.removeAll()
                    for iceServer in configuration.igpIceServer {
                        signaling.iceServer.append(IGIceServer(iceServer: iceServer))
                    }
                } else {
                    IGDatabaseManager.shared.realm.add(IGSignaling(signalingConfiguration: configuration))
                }
            }
        }
    }

    func setCallLog(callLog: IGPSignalingGetLogResponse.IGPSignalingLog) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %lld", callLog.igpID)
                if let _ = IGDatabaseManager.shared.realm.objects(IGRealmCallLog.self).filter(predicate).first {
                    IGDatabaseManager.shared.realm.add(IGRealmCallLog(signalingLog: callLog), update: .modified)
                } else {
                    IGDatabaseManager.shared.realm.add(IGRealmCallLog(signalingLog: callLog))
                }
            }
        }
    }

    func clearCallLogs() {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let callLogs = try! Realm().objects(IGRealmCallLog.self)
                if !callLogs.isEmpty {
                    IGDatabaseManager.shared.realm.delete(callLogs)
                }
            }
        }
    }
    func clearCallLog(array:[Int64]) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                for elemnt in array {
                    let predicate = NSPredicate(format: "id = %lld", elemnt)
                    if let tmpLog = try! Realm().objects(IGRealmCallLog.self).filter(predicate).first {
                        IGDatabaseManager.shared.realm.delete(tmpLog)
                    }
                }
            }
        }
    }

    func setMapNearbyUsersDistance(nearbyDistance: IGPGeoGetNearbyDistanceResponse.IGPResult) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %lld", nearbyDistance.igpUserID)
                if let _ = IGDatabaseManager.shared.realm.objects(IGRealmMapNearbyDistance.self).filter(predicate).first {
                    IGDatabaseManager.shared.realm.add(IGRealmMapNearbyDistance(nearbyDistance: nearbyDistance), update: .modified)
                } else {
                    IGDatabaseManager.shared.realm.add(IGRealmMapNearbyDistance(nearbyDistance: nearbyDistance))
                }
            }
        }
    }

    func updateNearbyDistanceComment(userId: Int64, comment: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %lld", userId)
                if let nearbyDistance = IGDatabaseManager.shared.realm.objects(IGRealmMapNearbyDistance.self).filter(predicate).first {
                    nearbyDistance.comment = comment
                }
            }
        }
    }

    //MARK: --------------------------------------------------------
    //MARK: ▶︎▶︎ Rooms

    /* clear share info if "isParticipant == false" */
    func deleteShareInfo(removeRoom: Bool = true){
        /*
         //let task = getFactoryTask()
         factoryQueue.async {
         IGDatabaseManager.shared.perfrmOnDatabaseThread {

         var predicate = NSPredicate(format: "isParticipant != 1 AND type == %d", 4) //  contact == 4
         if removeRoom {
         predicate = NSPredicate(format: "isParticipant != 1 AND type != %d", 4)
         }
         let shareInfos = IGDatabaseManager.shared.realm.objects(IGShareInfo.self).filter(predicate)
         try! IGDatabaseManager.shared.realm.write {
         IGDatabaseManager.shared.realm.delete(shareInfos)
         }

         IGFactory.shared.performInFactoryQueue {
         //self.setFactoryTaskSuccess(task: task)
         }
         }
         }
         //self.doFactoryTask(task: task)
         */
    }

    func deleteShareInfo(id: Int64, isContact: Bool = true){
        /*
         //let task = getFactoryTask()
         factoryQueue.async {
         IGDatabaseManager.shared.perfrmOnDatabaseThread {

         var predicate = NSPredicate(format: "id == %lld AND type == %d", id, 4) //  contact == 4
         if !isContact {
         predicate = NSPredicate(format: "id == %lld AND type != %d", id, 4)
         }
         let shareInfos = IGDatabaseManager.shared.realm.objects(IGShareInfo.self).filter(predicate)
         try! IGDatabaseManager.shared.realm.write {
         IGDatabaseManager.shared.realm.delete(shareInfos)
         }

         IGFactory.shared.performInFactoryQueue {
         //self.setFactoryTaskSuccess(task: task)
         }
         }
         }
         //self.doFactoryTask(task: task)
         */
    }

    func removeShareInfoContactParticipant(){
        /*
         //let task = getFactoryTask()
         factoryQueue.async {
         IGDatabaseManager.shared.perfrmOnDatabaseThread {

         let predicate = NSPredicate(format: "isParticipant == 1 AND type == %d", 4) //  contact == 4
         let shareInfos = IGDatabaseManager.shared.realm.objects(IGShareInfo.self).filter(predicate)
         try! IGDatabaseManager.shared.realm.write {
         for shareInfo in shareInfos {
         shareInfo.isParticipant = false
         }
         }

         IGFactory.shared.performInFactoryQueue {
         //self.setFactoryTaskSuccess(task: task)
         }
         }
         }
         //self.doFactoryTask(task: task)
         */
    }

    func saveRoomsToDatabase(_ rooms: [IGPRoom], ignoreLastMessage: Bool, enableCache: Bool = false) {

        let task = IGFactoryTask()
        task.task = {
            IGDatabaseManager.shared.perfrmOnDatabaseThread {
                try! IGDatabaseManager.shared.realm.write {
                    for igpRoom in rooms {
                        IGDatabaseManager.shared.realm.add(IGRoom.putOrUpdate(realm: IGDatabaseManager.shared.realm, igpRoom))
                    }
                    
                    IGFactory.shared.performInFactoryQueue {
                        self.setFactoryTaskSuccess(task: task)
                    }
                }
                self.rewriteRoomInfo()
            }
        }
        task.success ({
            self.removeTaskFromQueueAndPerformNext(task)
        }).error ({
            self.removeTaskFromQueueAndPerformNext(task)
        }).addToQueue()

        self.performNextFactoryTaskIfPossible()
    }

    /* rewrite room info with "IGGlobal.rewriteRoomInfo" array */
    private func rewriteRoomInfo(){
        let cachedRooms = IGGlobal.rewriteRoomInfo
        IGGlobal.rewriteRoomInfo.removeAll()
        IGGlobal.importedRoomMessageDic.removeAll()
        try! IGDatabaseManager.shared.realm.write {
            for room in cachedRooms {
                IGDatabaseManager.shared.realm.add(IGRoom.putOrUpdate(room))
            }
        }
        /* if after rewrite room info added again item into "IGGlobal.rewriteRoomInfo" again call "rewriteRoomInfo" method */
        if IGGlobal.rewriteRoomInfo.count > 0 {
            rewriteRoomInfo()
        }
    }

    func saveRoomToDatabase(_ igpRoom: IGPRoom, isParticipant: Bool?) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.add(IGRoom.putOrUpdate(igpRoom), update: .modified)
            }
        }
    }

    func markAllMessagesAsRead(roomId: Int64, clearId: Int64 = 0) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                /* if clearId is lower than latest messageId don't clear message */
                if clearId == 0 || roomInDb.lastMessage == nil || (roomInDb.lastMessage?.id)! <= clearId {
                    try! IGDatabaseManager.shared.realm.write {
                        roomInDb.badgeUnreadCount = 0
                        roomInDb.unreadCount = 0
                    }
                }
            }
        }
    }

    func muteRoom(roomId: Int64, roomMute: IGRoom.IGRoomMute) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.mute = roomMute
                }
            }
        }
    }

    func pinRoom(roomId: Int64, pinId: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.pinId = pinId
                }
            }
        }
    }

    func promoteRoom(roomId: Int64, isPromote: Bool = true) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.isPromote = isPromote
                }
            }
        }
    }

    func clearPromote(roomId: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %lld", roomId)
                if let room = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                    room.isPromote = false
                }
            }
        }
    }

    func editChannelRooms(roomID : Int64 , roomName: String , roomDescription : String ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomID)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.title = roomName
                    roomInDb.channelRoom?.roomDescription = roomDescription
                }
            }
        }
    }

    func removeGroupUserName (_ roomID : Int64 ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomID)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.groupRoom?.type = .privateRoom
                    roomInDb.groupRoom?.publicExtra?.username = ""
                }
            }
        }
    }

    func romoveChannelUserName (_ roomID: Int64 ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomID)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.channelRoom?.type = .privateRoom
                    roomInDb.channelRoom?.publicExtra?.username = ""
                }
            }
        }
    }

    func editGroupRooms(roomID: Int64 , roomName: String , roomDesc: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let predicate = NSPredicate(format: "id = %lld", roomID)
            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.title = roomName
                    roomInDb.groupRoom?.roomDescription = roomDesc
                }
            }
        }
    }

    func updateGroupUsername(_ username: String, roomId: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomId)

            let publicExtraPredicate = NSPredicate(format: "id = %lld", roomId)
            var publicExtra: IGGroupPublicExtra!
            if let publicExtraInDb = IGDatabaseManager.shared.realm.objects(IGGroupPublicExtra.self).filter(publicExtraPredicate).first {
                publicExtra = publicExtraInDb
            } else {
                publicExtra = IGGroupPublicExtra(id: roomId, username: username)
            }

            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(roomPredicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    publicExtra.username = username
                    roomInDb.groupRoom?.type = .publicRoom
                    roomInDb.groupRoom?.publicExtra = publicExtra
                }
            }
        }
    }

    func updateChannelUserName( userName: String , roomID : Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomID)
            let publicExtraPredicate = NSPredicate(format: "id = %lld", roomID)

            if let roomInDb = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(roomPredicate).first {
                var publicExtra: IGChannelPublicExtra!
                if let publicExtraInDb = IGDatabaseManager.shared.realm.objects(IGChannelPublicExtra.self).filter(publicExtraPredicate).first {
                    publicExtra = publicExtraInDb
                } else {
                    publicExtra = IGChannelPublicExtra(id: roomID, username: userName)
                }

                try! IGDatabaseManager.shared.realm.write {
                    publicExtra.username = userName
                    roomInDb.channelRoom?.type = .publicRoom
                    roomInDb.channelRoom?.publicExtra = publicExtra
                    roomInDb.channelRoom?.privateExtra = nil
                }
            }
        }
    }

    func updatChannelRoomSignature(_ roomId: Int64 , signatureStatus: Bool) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.channelRoom?.isSignature = signatureStatus
                }
            }
        }
    }

    func revokePrivateRoomLink(roomId: Int64 , invitedLink: String , invitedToken: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    if roomInDb.channelRoom != nil {
                        roomInDb.channelRoom?.privateExtra?.inviteLink = invitedLink
                        roomInDb.channelRoom?.privateExtra?.inviteToken = invitedToken
                    }
                    if roomInDb.groupRoom != nil {
                        roomInDb.groupRoom?.privateExtra?.inviteLink = invitedLink
                        roomInDb.groupRoom?.privateExtra?.inviteToken = invitedToken
                    }
                }
            }
        }
    }


    func setActionForRoom(action: IGClientAction, userId:Int64, roomId: Int64) {
        IGFactoryTask(dependencyRoomTask: roomId, isParticipane: true).success({
            IGFactoryTask(dependencyUserTask: userId, cacheID: nil).success({
                let userPredicate = NSPredicate(format: "id = %lld", userId)
                let roomPredicate = NSPredicate(format: "id = %lld", roomId)
                if let user = try! Realm().objects(IGRegisteredUser.self).filter(userPredicate).first, let room = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {
                    let userRef = ThreadSafeReference(to: user)
                    let roomRef = ThreadSafeReference(to: room)

                    IGRoomManager.shared.set(action, for: roomRef, from: userRef)
                }
                //self.setFactoryTaskSuccess(task: task)
            }).error({
                //self.setFactoryTaskError(task: task)
            }).execute()
        }).error({
            //self.setFactoryTaskError(task: task)
        }).execute()
    }

    //MARK: --------------------------------------------------------
    //MARK: ▶︎▶︎ File
    /* just use this method for sticker. because we need insert info
     * with file type, and file type detection is impossible.
     * for example detect current file info is for image or sticker ?!
     */
    func addStickerFileToDatabse(igpFile: IGPFile, completion: @escaping ((_ token :IGPFile) -> Void)) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            var newFile: IGFile!

            try! IGDatabaseManager.shared.realm.write {
                newFile = IGFile.putOrUpdate(igpFile: igpFile, fileType: FileType.sticker, filePathType: .sticker)
                IGDatabaseManager.shared.realm.add(newFile)
            }

            completion(igpFile)
        }
    }

    func saveDraft(draft: IGRoomDraft) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", draft.roomId)
            if let roomInDb = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    let draftInDb = IGRoomDraft.putOrUpdate(message: draft.message, roomId: draft.roomId)
                    roomInDb.draft = draftInDb
                    if draftInDb.time != 0 { // if has draft time, update value to sortimgTimestamp fot sort in room list
                        roomInDb.sortimgTimestamp = Double(draftInDb.time)
                    } else {
                        if let lastMessage = roomInDb.lastMessage {
                            let predicateMessage = NSPredicate(format: "id = %lld AND roomId = %lld", (lastMessage.id), roomInDb.id)
                            if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicateMessage).first {
                                roomInDb.sortimgTimestamp = (messageInDb.creationTime?.timeIntervalSinceReferenceDate)!
                            }
                        } else {
                            roomInDb.sortimgTimestamp = 0
                        }
                    }
                }
            }
        }
    }

    func saveDraft(roomId: Int64, igpDraft: IGPRoomDraft) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    let draftInDb = IGRoomDraft.putOrUpdate(realm: IGDatabaseManager.shared.realm, igpDraft: igpDraft, roomId: roomId)
                    roomInDb.draft = draftInDb
                    if draftInDb.time != 0 { // if has draft time, update value to sortimgTimestamp fot sort in room list
                        roomInDb.sortimgTimestamp = Double(draftInDb.time)
                    } else {
                        if let lastMessage = roomInDb.lastMessage {
                            let predicateMessage = NSPredicate(format: "id = %lld AND roomId = %lld", (lastMessage.id), roomInDb.id)
                            if let messageInDb = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicateMessage).first {
                                roomInDb.sortimgTimestamp = (messageInDb.creationTime?.timeIntervalSinceReferenceDate)!
                            }
                        } else {
                            roomInDb.sortimgTimestamp = 0
                        }
                    }
                }
            }
        }
    }

    func convertChatToGroup(roomId: Int64, roomName: String , roomRole: IGPGroupRoom.IGPRole, roomDescription: String ) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {
                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.type = .group
                    roomInDb.isParticipant = true
                    roomInDb.title = roomName
                    roomInDb.groupRoom?.roomDescription = roomDescription
                    roomInDb.groupRoom?.role = roomRole
                    roomInDb.sortimgTimestamp = Date().timeIntervalSinceReferenceDate
                }
            }
        }
    }

    func roomPinMessage(roomId: Int64, messageId: Int64 = 0) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            let roomPredicate = NSPredicate(format: "id = %lld", roomId)
            if let roomInDb = try! Realm().objects(IGRoom.self).filter(roomPredicate).first {

                var pinMessage : IGRoomMessage? = nil

                if messageId != 0 {
                    let messagePredicate = NSPredicate(format: "id = %lld", messageId)
                    pinMessage = try! Realm().objects(IGRoomMessage.self).filter(messagePredicate).first
                }

                try! IGDatabaseManager.shared.realm.write {
                    roomInDb.pinMessage = pinMessage
                    if messageId == 0 {
                        if pinMessage != nil {
                            roomInDb.deletedPinMessageId = (pinMessage?.id)!
                        }
                    }
                }
            }
        }
    }
    
    func manageUnreadMessage(roomId: Int64, roomType: IGRoom.IGType, message: IGPRoomMessage){
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let room = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(NSPredicate(format: "id = %lld", roomId)).first
                let message = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(NSPredicate(format: "id = %lld", message.igpMessageID)).first
                
                if room != nil && message != nil {
                    /**
                     * client checked (room.unreadCount <= 1) because in IGHelperMessage unreadCount++
                     */
                    if (room!.unreadCount <= Int32(1)) {
                        message?.futureMessageId = message!.id
                        room?.firstUnreadMessage = message
                    }
                }
            }
        }
    }

    func saveWallpaper(wallpapers: [IGPWallpaper], type: IGPInfoWallpaper.IGPType = .chatBackground) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                /** delete old wallpapers */
                IGDatabaseManager.shared.realm.delete(IGDatabaseManager.shared.realm.objects(IGRealmWallpaper.self).filter(NSPredicate(format: "type = %d", type.rawValue)))
                /** add new wallpapers */
                IGDatabaseManager.shared.realm.add(IGRealmWallpaper(wallpapers: wallpapers,typeOfWallpaper: type))
            }
        }
    }

    func setWallpaperFile(wallpaper: NSData?) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            if let wallpapers = IGDatabaseManager.shared.realm.objects(IGRealmWallpaper.self).first {
                try! IGDatabaseManager.shared.realm.write {
                    if wallpaper != nil {
                        wallpapers.selectedFile = wallpaper
                    } else {
                        wallpapers.selectedFile = nil
                    }
                }
            }
        }
    }

    func setWallpaperSolidColor(solidColor: String?) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {

            if let wallpapers = IGDatabaseManager.shared.realm.objects(IGRealmWallpaper.self).first {
                try! IGDatabaseManager.shared.realm.write {
                    wallpapers.selectedColor = solidColor
                }
            }
        }
    }

    func addOfflineSeen(roomId: Int64, messageId: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.add(IGRealmOfflineSeen(roomId: roomId, messageId: messageId))
            }
        }
    }

    func removeOfflineSeen(roomId: Int64, messageId: Int64, status: IGPRoomMessageStatus) {
        if status != .seen {return}

        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let offlineSeen = IGDatabaseManager.shared.realm.objects(IGRealmOfflineSeen.self).filter("roomId = %lld", roomId).first {
                    IGDatabaseManager.shared.realm.delete(offlineSeen)
                }
            }
        }
    }


    func addSticker(stickers: [StickerTab]) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {

                for sticker in stickers {
                    let stickerItems: List<IGRealmStickerItem> = List<IGRealmStickerItem>()
                    for stickerItem in sticker.stickers {
                        stickerItems.append(IGRealmStickerItem(sticker: stickerItem))
                    }

                    IGDatabaseManager.shared.realm.add(IGRealmSticker(sticker: sticker, stickerItems: stickerItems), update: .modified)
                }
            }
        }
    }

    func removeSticker(groupId: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %@", groupId)
                if let stickerItem = IGDatabaseManager.shared.realm.objects(IGRealmSticker.self).filter(predicate).first {
                    IGDatabaseManager.shared.realm.delete(stickerItem)
                }
            }
        }
    }

    func removeAllSticker() {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.delete(IGDatabaseManager.shared.realm.objects(IGRealmSticker.self))
            }
        }
    }


    func addDiscoveryPageInfo(discoveryList: [IGPDiscovery]) {
        removeDiscoveryPageInfo()
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                for discovery in discoveryList {
                    IGDatabaseManager.shared.realm.add(IGRealmDiscovery(discovery: discovery))
                }
            }
        }
    }

    func removeDiscoveryPageInfo() {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                IGDatabaseManager.shared.realm.delete(IGDatabaseManager.shared.realm.objects(IGRealmDiscovery.self))
                IGDatabaseManager.shared.realm.delete(IGDatabaseManager.shared.realm.objects(IGRealmDiscoveryField.self))
            }
        }
    }

    func setRepresenter(phoneNumber: String) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                if let session = IGDatabaseManager.shared.realm.objects(IGSessionInfo.self).first {
                    session.representer = phoneNumber
                }
            }
        }
    }

    func clearGap(roomId: Int64, fromPosition: Int64, toPosition: Int64) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                // TODO - set all these values with list, without loop
                let predicate = NSPredicate(format: "roomId = %lld AND id >= %lld AND id <= %lld", roomId, fromPosition, toPosition)
                for realmRoomMessage in IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate) {
                    realmRoomMessage.previousMessageId = 0
                    realmRoomMessage.futureMessageId = 0
                }
            }
        }
    }

    /* if don't set direction, messageId will be set for both of previousMessageId & futureMessageId */
    func setGap(messageId: Int64, direction: IGPClientGetRoomHistory.IGPDirection? = nil) {
        IGDatabaseManager.shared.perfrmOnDatabaseThread {
            try! IGDatabaseManager.shared.realm.write {
                let predicate = NSPredicate(format: "id = %lld", messageId)
                if let realmRoomMessage = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                    if direction == nil {
                        realmRoomMessage.previousMessageId = messageId
                        realmRoomMessage.futureMessageId = messageId
                    } else {
                        if (direction == .up) {
                            realmRoomMessage.previousMessageId = messageId
                        } else {
                            realmRoomMessage.futureMessageId = messageId
                        }
                    }
                }
            }
        }
    }

    func updateFirstUnreadMessage(roomId: Int64, messageId: Int64) {
        //TODO - call this method after set message into the db
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            IGDatabaseManager.shared.perfrmOnDatabaseThread {
                try! IGDatabaseManager.shared.realm.write {

                    let predicateRoom = NSPredicate(format: "id = %lld", roomId)
                    if let room = IGDatabaseManager.shared.realm.objects(IGRoom.self).filter(predicateRoom).first, room.unreadCount <= 1 {
                        let predicate = NSPredicate(format: "id = %lld", messageId)
                        if let realmRoomMessage = IGDatabaseManager.shared.realm.objects(IGRoomMessage.self).filter(predicate).first {
                            realmRoomMessage.futureMessageId = realmRoomMessage.id
                            room.firstUnreadMessage = realmRoomMessage
                        }
                    }
                }
            }
        }
    }
}
