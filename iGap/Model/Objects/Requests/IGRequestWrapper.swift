/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import Foundation
import IGProtoBuff
import SwiftProtobuf
//import SwiftProtobuf

//TODO: rename this to IGRequestTask
class IGRequestWrapper: NSObject {
    
    
    var id       = ""
    var actionId = 0
    var message  : RequestMessage!
    var identity : Any?
    var time     : Int64!
    var IV       = Data()
    
    //optional properties to handle inner objects
    var uploadTask : IGUploadTask?
    var downloadTask : IGDownloadTask?
    var messageSenderTask: IGMessageSenderTask?
    var room: IGRoom?
    
    var success: ((ResponseMessage)->())? // simple success just return server response
    var successPowerful: ((ResponseMessage, IGRequestWrapper)->())? //successPowerful has IGRequestWrapper for use identity or another info that used in send request
    var error: ((IGError, IGErrorWaitTime?)->())?
    var errorPowerful: ((IGError, IGErrorWaitTime?, IGRequestWrapper)->())? // errorPowerful has IGRequestWrapper for use identity or another info that used in send request
    
    
    init(message: RequestMessage!, actionID:Int) {
        self.message = message
        self.actionId = actionID
    }
    
    init(message: RequestMessage!, actionID:Int, identity:Any?) {
        self.message = message
        self.actionId = actionID
        self.identity = identity
    }
    
    @discardableResult
    func success(_ sucess: @escaping (ResponseMessage)->()) -> IGRequestWrapper {
        self.success = sucess
        return self
    }
    
    @discardableResult
    func successPowerful(_ successPowerful: @escaping (ResponseMessage, IGRequestWrapper)->()) -> IGRequestWrapper {
        self.successPowerful = successPowerful
        return self
    }
    
    @discardableResult
    func error(_ error: @escaping (IGError, IGErrorWaitTime?)->()) -> IGRequestWrapper {
        self.error = error
        return self
    }
    
    @discardableResult
    func errorPowerful(_ errorPowerful: @escaping (IGError, IGErrorWaitTime?, IGRequestWrapper)->()) -> IGRequestWrapper {
        self.errorPowerful = errorPowerful
        return self
    }
    
    @discardableResult
    func send() -> IGRequestWrapper {
        IGRequestManager.sharedManager.addRequestIDAndSend(requestWrappers: self)
        return self
    }
}

