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
import RealmSwift

class IGHelperForward {
    private static var makeChatArray : [Int64] = []
    private static var messagesStatic : [IGRoomMessage] = []
    private static var forwardModalStatic: IGMultiForwardModalViewController!
    
    internal static func handleForward(messages: [IGRoomMessage] = [], forwardModal: IGMultiForwardModalViewController!, controller: UIViewController? = nil, isFromCloud: Bool = false) {
        if forwardModal.selectedItems.count == 1 { // single user or room was selected
            singleForward(messages: messages, forwardModal: forwardModal, controller: controller, isFromCloud : isFromCloud)
        } else {
            multiForward(messages: messages, forwardModal: forwardModal)
        }
    }
    
    private static func singleForward(messages: [IGRoomMessage] = [], forwardModal: IGMultiForwardModalViewController!, controller: UIViewController? = nil, isFromCloud: Bool = false){
        
        var viewController: UIViewController! = controller
        if viewController == nil {
            viewController = UIApplication.topViewController()
        }
        
        for selectedItem in forwardModal.selectedItems {
            if selectedItem.typeRaw == IGRoom.IGType.chat {
                if let room = IGRoom.existRoomInLocal(userId: selectedItem.id) {
                    openChat(room: room, messageArray: messages, viewController: viewController)
                } else {
                    IGGlobal.prgShow(viewController.view)
                    IGChatGetRoomRequest.Generator.generate(peerId: selectedItem.id).success({ (protoResponse) in
                        DispatchQueue.main.async {
                            IGGlobal.prgHide()
                            if let chatGetRoomResponse = protoResponse as? IGPChatGetRoomResponse {
                                let _ = IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                                let room = IGRoom(igpRoom: chatGetRoomResponse.igpRoom)
                                openChat(room: room, messageArray: messages, viewController: viewController)
                            }
                        }
                    }).error({ (errorCode, waitTime) in
                        DispatchQueue.main.async {
                            IGGlobal.prgHide()
                            let alertC = UIAlertController(title: "Error", message: "An error occured trying to create a conversation", preferredStyle: .alert)
                            let cancel = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertC.addAction(cancel)
                            viewController.present(alertC, animated: true, completion: nil)
                        }
                    }).send()
                }
            } else {
                if let room = IGRoom.existRoomInLocal(roomId: selectedItem.id) {
                    openChat(room: room, messageArray: messages, viewController: viewController)
                }
            }
        }
    }
    
    private static func multiForward(messages: [IGRoomMessage] = [], forwardModal: IGMultiForwardModalViewController!){
        messagesStatic = messages
        forwardModalStatic = forwardModal
        
        for selectedRoom in forwardModal.selectedItems {
            if selectedRoom.typeRaw == .chat {
                let room = IGRoom.existRoomInLocal(userId: selectedRoom.id)
                if room == nil {
                    makeChatArray.append(selectedRoom.id)
                }
            }
        }
        
        /* make chat room with server if not exist in local or not created yet */
        if makeChatArray.count > 0 {
            IGGlobal.prgShow()
            makeChatRoom()
            return
        }
        
        for selectedRoom in forwardModal.selectedItems {
            var room: IGRoom!
            if selectedRoom.typeRaw == .chat {
                room = IGRoom.existRoomInLocal(userId: selectedRoom.id)
            } else {
                room = IGRoom.existRoomInLocal(roomId: selectedRoom.id)
            }
            
            if room == nil {break}
            
            for forwardedMessage in messages {
                IGMessageSender.defaultSender.send(message: makeSingleForwardMessage(room: room, forwardedMessage: forwardedMessage), to: room)
            }
        }
    }
    
    private static func makeForwardMessageArray(room: IGRoom, messages: [IGRoomMessage], isFromCloud: Bool = false) -> [IGRoomMessage]? {
        var forwardedMessages : [IGRoomMessage] = []
        for forwardedMessage in messages {
            if isFromCloud == true && (forwardedMessage.forwardedFrom == nil) {
                let messageText = (forwardedMessage.message)
                let message = IGRoomMessage(body: messageText!)
                message.type = forwardedMessage.type
                message.attachment = forwardedMessage.attachment

                message.roomId = room.id
                let detachedMessage = message.detach()
                IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
                forwardedMessages.append(message)

            } else {
                let message = IGRoomMessage(body: "")
                message.type = .text
                message.roomId = room.id
                let detachedMessage = message.detach()
                IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
                message.forwardedFrom = forwardedMessage // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
                forwardedMessages.append(message)
            }

            
        }

        if forwardedMessages.count > 0 {
            return forwardedMessages
        }
        return nil
    }
    
    private static func makeForward(room: IGRoom, messages: [IGRoomMessage], isFromCloud: Bool = false, completion: @escaping (_ messages: [ThreadSafeReference<IGRoomMessage>]) -> Void) {
        var forwardedMessages : [ThreadSafeReference<IGRoomMessage>] = []
        for forwardedMessage in messages {
            IGFactory.shared.saveForwardMessage(roomId: room.id, messageId: forwardedMessage.id, completion: { (message) in
                forwardedMessages.append(ThreadSafeReference(to: message))
                if forwardedMessages.count == messages.count {
                    completion(forwardedMessages)
                }
            })
        }
    }
    
    private static func makeSingleForwardMessage(room: IGRoom, forwardedMessage: IGRoomMessage,isFromCloud: Bool = false) -> IGRoomMessage {
        if isFromCloud == true && (forwardedMessage.forwardedFrom == nil) {
            let messageText = (forwardedMessage.message)
            let message = IGRoomMessage(body: messageText!)
            message.type = forwardedMessage.type
            message.attachment = forwardedMessage.attachment

            message.roomId = room.id
            let detachedMessage = message.detach()
            IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
            return message

        } else {
            let message = IGRoomMessage(body: "")
            message.type = .text
            message.roomId = room.id
            let detachedMessage = message.detach()
            IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
            message.forwardedFrom = forwardedMessage // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
            return message
        }
    }
    
    private static func makeChatRoom(index: Int = 0){
        if makeChatArray.count <= index {
            IGGlobal.prgHide()
            makeChatArray.removeAll()
            DispatchQueue.main.async {
                handleForward(messages: messagesStatic, forwardModal: forwardModalStatic)
            }
            return
        }
        
        let peerId = self.makeChatArray[index]
        IGChatGetRoomRequest.Generator.generate(peerId: peerId).success({ (protoResponse) in
            if let chatGetRoomResponse = protoResponse as? IGPChatGetRoomResponse {
                print("RRR || title: \(chatGetRoomResponse.igpRoom.igpTitle)")
                let _ = IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                makeChatRoom(index: index + 1)
            }
        }).error({ (errorCode, waitTime) in
            makeChatRoom(index: index + 1)
        }).send()
    }
    
    private static func openChat(room: IGRoom, messageArray: [IGRoomMessage] = [], viewController: UIViewController){
        DispatchQueue.main.async {
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let roomVC = storyboard.instantiateViewController(withIdentifier: "IGMessageViewController") as! IGMessageViewController
            roomVC.room = room
            roomVC.forwardedMessageArray = messageArray
            roomVC.hidesBottomBarWhenPushed = true
            viewController.navigationController!.pushViewController(roomVC, animated: true)
        }
    }
}
