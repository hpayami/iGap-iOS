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
import UIKit
import IGProtoBuff
import SwiftProtobuf
import RealmSwift
import WebRTC
import CoreTelephony

class IGSignalingGetConfigurationRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate() -> IGRequestWrapper {
            return IGRequestWrapper(message: IGPSignalingGetConfiguration(), actionID: 900)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingGetConfigurationResponse) {
            IGFactory.shared.setSignalingConfiguration(configuration: reponseProtoMessage)
            for ice in reponseProtoMessage.igpIceServer {
                IGAppManager.iceServersStatic.append(RTCIceServer(urlStrings:[ice.igpURL],username:ice.igpUsername,credential:ice.igpCredential))
            }
        }

        override class func handlePush(responseProtoMessage: Message) {
            switch responseProtoMessage {
            case let getConfigurationProtoResponse as IGPSignalingGetConfigurationResponse:
                self.interpret(response: getConfigurationProtoResponse)
            default:
                break
            }
        }
    }
}


class IGSignalingOfferRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(calledUserId: Int64,type: IGPSignalingOffer.IGPType,callerSdp : String) -> IGRequestWrapper {
            var offerRequestMessage = IGPSignalingOffer()
            offerRequestMessage.igpCalledUserID = calledUserId
            offerRequestMessage.igpType = type
            offerRequestMessage.igpCallerSdp = callerSdp
            return IGRequestWrapper(message: offerRequestMessage, actionID: 901)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingOfferResponse) {
            IGCall.sendLeaveRequest = true
            IGCall.callTypeStatic = reponseProtoMessage.igpType
        }

        override class func handlePush(responseProtoMessage: Message) {
            if let offerProtoResponse = responseProtoMessage as? IGPSignalingOfferResponse {
                IGSignalingOfferRequest.Handler.interpret(response: offerProtoResponse)
                
                /* reject video call if user cellular call is connected  */
                if offerProtoResponse.igpType == .videoCalling && IGCallEventListener.callState == CTCallStateConnected {
                    IGSignalingLeaveRequest.Generator.generate().success({ (protoResponse) in }).error ({ (errorCode, waitTime) in }).send()
                    return
                }
                
                DispatchQueue.main.async {

                    (UIApplication.shared.delegate as! AppDelegate).showCallPage(userId: offerProtoResponse.igpCallerUserID,
                                                                                 sdp: offerProtoResponse.igpCallerSdp,
                                                                                 type: offerProtoResponse.igpType)
                }
            }
        }
    }
}


class IGSignalingRingingRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate() -> IGRequestWrapper {
            return IGRequestWrapper(message: IGPSignalingRinging(), actionID: 902)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingRingingResponse)  {}

        override class func handlePush(responseProtoMessage: Message) {
            guard let delegate = RTCClient.getInstance()?.callStateDelegate else {
                return
            }
            delegate.onStateChange(state: RTCClientConnectionState.Ringing)
        }
    }
}

class IGSignalingAcceptRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(calledSdp: String) -> IGRequestWrapper {
            var acceptRequestMessage = IGPSignalingAccept()
            acceptRequestMessage.igpCalledSdp = calledSdp
            return IGRequestWrapper(message: acceptRequestMessage, actionID: 903)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingAcceptResponse)  {
            IGCall.sendLeaveRequest = true
        }

        override class func handlePush(responseProtoMessage: Message) {
            switch responseProtoMessage {
            case let acceptProtoResponse as IGPSignalingAcceptResponse:
                IGCall.sendLeaveRequest = true
                RTCClient.getInstance()?.handleAnswerReceived(withRemoteSDP: acceptProtoResponse.igpCalledSdp)
            default:
                break
            }
        }
    }
}


class IGSignalingCandidateRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(candidate: String,sdpMId: String,sdpMLineIndex: Int32) -> IGRequestWrapper {
            var candidateRequestMessage = IGPSignalingCandidate()
            candidateRequestMessage.igpCandidate = candidate
            candidateRequestMessage.igpSdpMID = sdpMId
            candidateRequestMessage.igpSdpMLineIndex = sdpMLineIndex
            return IGRequestWrapper(message: candidateRequestMessage, actionID: 904)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingCandidateResponse)  {}

        override class func handlePush(responseProtoMessage: Message) {
            switch responseProtoMessage {
            case let candidateResponse as IGPSignalingCandidateResponse:
                RTCClient.getInstance()?.addIceCandidate(iceCandidate: RTCIceCandidate(sdp: candidateResponse.igpPeerCandidate,sdpMLineIndex: candidateResponse.igpPeerSdpMLineIndex ,sdpMid: candidateResponse.igpPeerSdpMID))
                break
            default:
                break
            }
        }
    }
}


class IGSignalingLeaveRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate() -> IGRequestWrapper {
            return IGRequestWrapper(message: IGPSignalingLeave(), actionID: 905)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response responseProtoMessage:IGPSignalingLeaveResponse, repeatCount: Int = 0)  {
            
            guard let delegate = RTCClient.getInstance()?.callStateDelegate else {
                // Hint: do this action with delay because in this state seems to we need more time for open call page and activation protocl callbacks
                if repeatCount < 5 {
                    let repeatCountFinal = repeatCount + 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        IGSignalingLeaveRequest.Handler.interpret(response: responseProtoMessage, repeatCount: repeatCountFinal)
                    }
                }
                return
            }
            
            switch responseProtoMessage.igpType {
                
            case IGPSignalingLeaveResponse.IGPType.accepted:
                delegate.onStateChange(state: RTCClientConnectionState.Accepted)
                break
                
            case IGPSignalingLeaveResponse.IGPType.disconnected:
                delegate.onStateChange(state: RTCClientConnectionState.Disconnected)
                break
                
            case IGPSignalingLeaveResponse.IGPType.finished:
                delegate.onStateChange(state: RTCClientConnectionState.Finished)
                break
                
            case IGPSignalingLeaveResponse.IGPType.missed:
                delegate.onStateChange(state: RTCClientConnectionState.Missed)
                break
                
            case IGPSignalingLeaveResponse.IGPType.notAnswered:
                delegate.onStateChange(state: RTCClientConnectionState.NotAnswered)
                break
                
            case IGPSignalingLeaveResponse.IGPType.rejected:
                delegate.onStateChange(state: RTCClientConnectionState.Rejected)
                break
                
            case IGPSignalingLeaveResponse.IGPType.tooLong:
                delegate.onStateChange(state: RTCClientConnectionState.TooLong)
                break
                
            case IGPSignalingLeaveResponse.IGPType.unavailable:
                delegate.onStateChange(state: RTCClientConnectionState.Unavailable)
                break
                
            default:
                break
            }
            
            RTCClient.getInstance(justReturn: true)?.disconnect()
        }

        override class func handlePush(responseProtoMessage: Message) {
            if let signalingResponse = responseProtoMessage as? IGPSignalingLeaveResponse {
                self.interpret(response: signalingResponse)
            }
        }
    }
}


class IGSignalingSessionHoldRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(isOnHold: Bool) -> IGRequestWrapper {
            var sessionHoldRequestMessage = IGPSignalingSessionHold()
            sessionHoldRequestMessage.igpHold = isOnHold
            return IGRequestWrapper(message: sessionHoldRequestMessage, actionID: 906)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingSessionHoldResponse)  {
            if reponseProtoMessage.igpResponse.igpID.isEmpty { // received response without send request
                IGCall.callHold?.onHoldCall(isOnHold: reponseProtoMessage.igpHold)
            }
        }

        override class func handlePush(responseProtoMessage: Message) {
            switch responseProtoMessage {
            case let sessionHoldProtoResponse as IGPSignalingSessionHoldResponse:
                self.interpret(response: sessionHoldProtoResponse)
            default:
                break
            }
        }
    }
}


class IGSignalingGetLogRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(offset: Int32, limit: Int32, mode : IGPSignalingGetLog.IGPFilter) -> IGRequestWrapper {
            var signalingGetLog = IGPSignalingGetLog()
            var pagination = IGPPagination()
            pagination.igpLimit = limit
            pagination.igpOffset = offset
            signalingGetLog.igpPagination = pagination
            signalingGetLog.igpFilter = mode
            return IGRequestWrapper(message: signalingGetLog, actionID: 907)
        }
    }
    
    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingGetLogResponse) -> Int {
            
            for callLog in reponseProtoMessage.igpSignalingLog {
                IGFactory.shared.setCallLog(callLog: callLog)
            }
            
            return reponseProtoMessage.igpSignalingLog.count
        }
        
        override class func handlePush(responseProtoMessage: Message) {
            if let callLogResponse = responseProtoMessage as? IGPSignalingGetLogResponse {
                let _ = self.interpret(response: callLogResponse)
            }
        }
    }
}


class IGSignalingClearLogRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(clearId: Int64? = nil , logIDArray : [Int64]? = nil) -> IGRequestWrapper {
            var clearLogRequestMessage = IGPSignalingClearLog()
            if logIDArray?.count ?? 0 > 0 , logIDArray != nil {
                for elemnt in logIDArray! {
                    clearLogRequestMessage.igpLogID.append(elemnt)
                }
            } else {
                clearLogRequestMessage.igpClearID = clearId!
            }
            return IGRequestWrapper(message: clearLogRequestMessage, actionID: 908)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingClearLogResponse)  {
            IGFactory.shared.clearCallLogs()
        }
        class func interpretClearUsingArray(response reponseProtoMessage:IGPSignalingClearLogResponse,array: [Int64])  {
            IGFactory.shared.clearCallLog(array:array)
            
        }

        override class func handlePush(responseProtoMessage: Message) {
            switch responseProtoMessage {
            case let clearLogProtoResponse as IGPSignalingClearLogResponse:
                self.interpret(response: clearLogProtoResponse)
            default:
                break
            }
        }
    }
}


class IGSignalingRateRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(id: Int64,rate: Int32,reason: String) -> IGRequestWrapper {
            var rateRequestMessage = IGPSignalingRate()
            rateRequestMessage.igpID = id
            rateRequestMessage.igpRate = rate
            rateRequestMessage.igpReason = reason
            return IGRequestWrapper(message: rateRequestMessage, actionID: 909)
        }
    }

    class Handler : IGRequest.Handler{
        class func interpret(response reponseProtoMessage:IGPSignalingRateResponse)  {}

        override class func handlePush(responseProtoMessage: Message) {
            switch responseProtoMessage {
            case let rateProtoResponse as IGPSignalingRateResponse:
                self.interpret(response: rateProtoResponse)
            default:
                break
            }
        }
    }
}
