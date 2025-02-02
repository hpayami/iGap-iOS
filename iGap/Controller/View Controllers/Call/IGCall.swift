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
import RealmSwift
import AVFoundation
import IGProtoBuff
import SnapKit
import WebRTC
import CallKit

class IGCall: UIViewController, CallStateObserver, ReturnToCallObserver, VideoCallObserver, RTCEAGLVideoViewDelegate, CallHoldObserver, CallManagerDelegate {
    var pulseLayers = [CAShapeLayer]()

    @IBOutlet weak var viewNameHolder: UIView!
    @IBOutlet weak var viewNameCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var imgAvatarInner: UIImageViewX!
    @IBOutlet weak var imgAvatarView: UIImageViewX!
    @IBOutlet weak var viewTransparent: UIView!
    @IBOutlet weak var txtiGap: UILabel!
    @IBOutlet weak var lblIcon: UILabel!
    @IBOutlet weak var txtCallerName: UILabel!
    @IBOutlet weak var txtCallState: UILabel!
    @IBOutlet weak var txtCallTime: UILabel!
    @IBOutlet weak var txtPowerediGap: UILabel!
    @IBOutlet weak var btnAnswer: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnMute: UIButton!
    @IBOutlet weak var btnChat: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnSwitchCamera: UIButton!
    @IBOutlet weak var localCameraView: RTCEAGLVideoView!
    @IBOutlet weak var remoteCameraView: RTCEAGLVideoView!
    @IBOutlet weak var holdView: UIView!
    @IBOutlet weak var txtHold: UILabel!
    var callerName : String? = IGStringsManager.Unknown.rawValue.localized
    
    let SWITCH_CAMERA_DELAY : Int64 = 1000
    let mainWidth = UIScreen.main.bounds.width
    let mainHeight = UIScreen.main.bounds.height
    
    var userId: Int64!
    var isIncommingCall: Bool!
    var isIncommingReturnCall: Bool!
    var callSdp: String?
    var callType: IGPSignalingOffer.IGPType = .voiceCalling
    var bottomViewsIsHidden = false
    
    private var remoteTrack: RTCVideoTrack!
    private var room: IGRoom!
    private var isSpeakerEnable = false
    private var isMuteEnable = false
    private var callIsConnected = false
    private var callTimer: Timer!
    var recordedTime: Int = 0
    private var player: AVAudioPlayer?
    private var remoteTrackAdded: Bool = false
    private var latestSwitchCamera: Int64 = IGGlobal.getCurrentMillis()
    private var isOnHold = false
    private var phoneNumber: String!
    private var latestRemoteVideoSize: CGSize!
    private var latestLocalVideoSize: CGSize!
    var isReturnCall : Bool = false
    private static var allowEndCallKit = true
    internal static var callTypeStatic: IGPSignalingOffer.IGPType = .voiceCalling
    internal static var callUUID = UUID()
    internal static var staticConnectionState: RTCClientConnectionState?
    internal static var sendLeaveRequest = true
    internal static var callPageIsEnable = false // this varibale will be used for detect that call page is enable or no. connection state of call isn't important now!
    internal static var staticReturnToCall: ReturnToCallObserver!
    internal static var callHold: CallHoldObserver!
    
    var callMinute: Int! = 0
    var callSec : Int! = 0
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRoomMessages" {
            let navigationController = segue.destination as! IGNavigationController
            let messageViewController = navigationController.topViewController as! IGMessageViewController
            messageViewController.room = room
            messageViewController.customizeBackItem = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        UIDevice.current.setValue(Int(UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
//        if #available(iOS 10.0, *), callType == .voiceCalling{
//            CallManager.sharedInstance.endCall()
//        } else {
//            dismmis()
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false //enable sleep mode
        UIDevice.current.isProximityMonitoringEnabled = false


    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true //disable sleep mode
        UIDevice.current.isProximityMonitoringEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        animateNameView(state: false)

        viewTransparent.backgroundColor = .clear
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 3.0)
        let whiteColor = ThemeManager.currentTheme.BackGroundColor
        gradient.colors = [UIColor.clear.cgColor, whiteColor.cgColor, whiteColor.cgColor]
        gradient.locations = [NSNumber(value: 0.0), NSNumber(value: 0.2), NSNumber(value: 1.0)]
        gradient.frame = viewTransparent.frame
        viewTransparent.layer.addSublayer(gradient)
        
        let realm = try! Realm()
        let predicate = NSPredicate(format: "id = %lld", userId)
        guard let userRegisteredInfo = realm.objects(IGRegisteredUser.self).filter(predicate).first else {
            return
        }
   
        phoneNumber = String(describing: userRegisteredInfo.phone)
        if isReturnCall {
//                    IGCall.callUUID = UUID()
//                    if #available(iOS 10.0, *), self.callType == .voiceCalling, self.isIncommingCall {
//
//                            if self.phoneNumber == "0" {
//                                CallManager.sharedInstance.reportIncomingCallFor(uuid: IGCall.callUUID, phoneNumber: userRegisteredInfo.displayName)
//
//                            }
//                            else {
//                                CallManager.sharedInstance.reportIncomingCallFor(uuid: IGCall.callUUID, phoneNumber: userRegisteredInfo.displayName)
//                            }
//
//
//                    }

                    if #available(iOS 10.0, *) {
                        CallManager.sharedInstance.delegate = self
                    }
                    self.remoteCameraView.delegate = self
                    self.localCameraView.delegate = self
                    IGCall.staticReturnToCall = self
                    IGCall.callHold = self
                    IGCall.callPageIsEnable = true
                    IGCall.allowEndCallKit = true
                    
                    localCameraViewCustomize()
                    setCallMode(callType: callType, userInfo: userRegisteredInfo)
                    let minute = String(format: "%02d", callMinute).inLocalizedLanguage()
                    let seconds = String(format: "%02d", callSec).inLocalizedLanguage()

                    txtCallTime.text = seconds + ":" + minute
                    if self.callTimer == nil {
                        self.callTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimerLabel), userInfo: nil, repeats: true)
                        self.callTimer?.fire()
                    }

            
                    if isIncommingReturnCall {
                        btnMute.isHidden = true
                        btnSpeaker.isHidden = true
                        btnChat.isHidden = true
            //            btnSwitchCamera.isHidden = true
                        txtCallTime.isHidden = false

                    } else {
                        btnMute.isHidden = false
                        btnSpeaker.isHidden = false
                        btnChat.isHidden = false
            //            btnSwitchCamera.isHidden = false
                        txtCallTime.isHidden = false
                        btnAnswer.isHidden = true
                        
                        btnCancel.snp.updateConstraints { (make) in
                            make.bottom.equalTo(btnChat.snp.top).offset(-54)
                            make.width.equalTo(70)
                            make.height.equalTo(70)
                            make.centerX.equalTo(self.view.snp.centerX)
                        }
                    }

            
            
            
                    txtCallerName.font = UIFont.igFont(ofSize: 23,weight: .bold)
                    holdView.layer.cornerRadius = 10
                    txtCallerName.text = userRegisteredInfo.displayName
                    txtCallState.text = IGStringsManager.Connected.rawValue.localized
                    
                    let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.tapOnMainView))
                    mainView.addGestureRecognizer(gesture)
                    
                    
                    
                    // for better tracking call state just send connecting state when user is login
          
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.createPulse()
                    }
                    btnSpeaker.setTitle("", for: .normal)
                    btnMute.setTitle("", for: .normal)
                    btnChat.setTitle("", for: .normal)
                    btnChat.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
                    btnMute.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
                    btnSpeaker.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)


        } else {
                    IGCall.callUUID = UUID()
                    if #available(iOS 10.0, *), self.callType == .voiceCalling, self.isIncommingCall {

                            if self.phoneNumber == "0" {
                                CallManager.sharedInstance.reportIncomingCallFor(uuid: IGCall.callUUID, phoneNumber: userRegisteredInfo.displayName)

                            }
                            else {
                                CallManager.sharedInstance.reportIncomingCallFor(uuid: IGCall.callUUID, phoneNumber: userRegisteredInfo.displayName)

                            }


                    }
                    if #available(iOS 10.0, *) {
                        CallManager.sharedInstance.delegate = self
                    }
                    self.remoteCameraView.delegate = self
                    self.localCameraView.delegate = self
                    IGCall.staticReturnToCall = self
                    IGCall.callHold = self
                    IGCall.callPageIsEnable = true
                    IGCall.allowEndCallKit = true
                    
                    localCameraViewCustomize()
            //        buttonViewCustomize(button: btnAnswer, color: UIColor(red: 44.0/255.0, green: 170/255.0, blue: 163.0/255.0, alpha: 1.0), imgName: "IG_Tabbar_Call_On")
                    setCallMode(callType: callType, userInfo: userRegisteredInfo)
                    manageView(stateAnswer: isIncommingCall)
                    txtCallerName.font = UIFont.igFont(ofSize: 23,weight: .bold)
                    holdView.layer.cornerRadius = 10
                    txtCallerName.text = userRegisteredInfo.displayName
            txtCallState.text = IGStringsManager.GlobalCommunicating.rawValue.localized
                    
                    let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.tapOnMainView))
                    mainView.addGestureRecognizer(gesture)
                    
                    RTCClient.getInstance()?
                        .initCallStateObserver(stateDelegate: self)
                        .initVideoCallObserver(videoDelegate: self)
                        .setCallType(callType: callType)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if self.isIncommingCall {
                            self.incommingCall()
                        } else {
                            self.outgoingCall(displayName: userRegisteredInfo.displayName)
                        }
                    }
                    
                    // for better tracking call state just send connecting state when user is login
                    if IGAppManager.sharedManager.isUserLoggiedIn() {
                        if self.callType == .voiceCalling {
                            IGHelperTracker.shared.sendTracker(trackerTag: IGHelperTracker.shared.TRACKER_VOICE_CALL_CONNECTING)
                        } else if self.callType == .videoCalling {
                            IGHelperTracker.shared.sendTracker(trackerTag: IGHelperTracker.shared.TRACKER_VIDEO_CALL_CONNECTING)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.createPulse()
                    }
                    btnSpeaker.setTitle("", for: .normal)
                    btnMute.setTitle("", for: .normal)
                    btnChat.setTitle("", for: .normal)
                    btnChat.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
                    btnMute.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
                    btnSpeaker.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)


        }
        btnSpeaker.setTitle("", for: .normal)
        btnMute.setTitle("", for: .normal)
        btnChat.setTitle("", for: .normal)
        btnChat.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
        btnMute.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
        btnSpeaker.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
        
        if self.callType == .videoCalling {
            btnChat.isEnabled = false
            
        }

    }
    
    //ANIMATIONS
    func createPulse() {
        for _ in 0...2 {
            let circularPath = UIBezierPath(arcCenter: .zero, radius: UIScreen.main.bounds.size.width/2.0, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            let pulseLayer = CAShapeLayer()
            pulseLayer.path = circularPath.cgPath
            pulseLayer.lineWidth = 1.0
            pulseLayer.fillColor = UIColor.clear.cgColor
            pulseLayer.lineCap = CAShapeLayerLineCap.round
            pulseLayer.position = CGPoint(x: lblIcon.frame.size.width/2.0, y: lblIcon.frame.size.width/2.0)
            imgAvatarView.layer.addSublayer(pulseLayer)
            pulseLayers.append(pulseLayer)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.animatePulse(index: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.animatePulse(index: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.animatePulse(index: 2)
                }
            }
        }
    }
    
    func animatePulse(index: Int) {
        pulseLayers[index].strokeColor = UIColor.black.cgColor
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 2.0
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 0.9
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        scaleAnimation.repeatCount = .greatestFiniteMagnitude
        pulseLayers[index].add(scaleAnimation, forKey: "scale")
        
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.duration = 2.0
        opacityAnimation.fromValue = 0.9
        opacityAnimation.toValue = 0.0
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        opacityAnimation.repeatCount = .greatestFiniteMagnitude
        pulseLayers[index].add(opacityAnimation, forKey: "opacity")
        
    }
    //end
    /************************************************/
    /************** User Actions Start **************/
    
    @IBAction func btnAnswer(_ sender: UIButton) {
        if #available(iOS 10.0, *), callType == .voiceCalling{
            CallManager.sharedInstance.startCall(phoneNumber: phoneNumber)
        } else {
            answerCall()
        }
    }
    
    @IBAction func btnCancel(_ sender: UIButton) {
        if #available(iOS 10.0, *), callType == .voiceCalling{
            CallManager.sharedInstance.endCall()
        } else {
            dismmis()
        }
    }
    
    @IBAction func btnMute(_ sender: UIButton) {
        muteManager()
    }
    
    @IBAction func btnSwitchCamera(_ sender: UIButton) {
        DispatchQueue.main.async {
            let currentTimeMillis = IGGlobal.getCurrentMillis()
            if currentTimeMillis - self.SWITCH_CAMERA_DELAY > self.latestSwitchCamera {
                self.latestSwitchCamera = currentTimeMillis
                RTCClient.getInstance(justReturn: true)?.switchCamera()
            }
        }
    }
    
    @IBAction func btnChat(_ sender: UIButton) {
//        self.gotToChat()
        self.dismiss(animated: true, completion: {
            if self.callTimer != nil {

                IGHelperUIViewView.shared.show(mode: .ReturnCall, userID: self.userId, isIncomming: self.isIncommingCall ?? false, lastRecordedTime : self.recordedTime)

        } else {

                if #available(iOS 10.0, *), self.callType == .voiceCalling{
                CallManager.sharedInstance.endCall()
            } else {
                    self.dismmis()
            }


        }
        })
    }
    
   private func gotToChat() {
        IGRecentsTableViewController.needGetInfo = false
        
        let realm = try! Realm()
        let predicate = NSPredicate(format: "chatRoom.peer.id = %lld", userId)
        if let roomInfo = realm.objects(IGRoom.self).filter(predicate).first {
            room = roomInfo
            performSegue(withIdentifier: "showRoomMessages", sender: self)
        } else {
            IGChatGetRoomRequest.Generator.generate(peerId: userId).success({ (protoResponse) in
                DispatchQueue.main.async {
                    if let chatGetRoomResponse = protoResponse as? IGPChatGetRoomResponse {
                        IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                        self.room = IGRoom(igpRoom: chatGetRoomResponse.igpRoom)
                        self.performSegue(withIdentifier: "showRoomMessages", sender: self)
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
    @IBAction func btnSpeaker(_ sender: UIButton) {
        IGCallAudioManager.sharedInstance.manageAudioState(viewController: self, btnAudioState: btnSpeaker)
    }
    
    @objc func tapOnMainView(sender : UITapGestureRecognizer) {
        changeBottomViewsVisibility()
    }
    
    /*************** User Actions End ***************/
    /************************************************/
    
    func onHoldCall(isOnHold: Bool) {
       hold(isOnHold: isOnHold, sendHoldRequest: false)
    }
    
    private func hold(isOnHold: Bool, sendHoldRequest: Bool = true){
        
        if sendHoldRequest {
            IGSignalingSessionHoldRequest.Generator.generate(isOnHold: isOnHold).success ({ (responseProtoMessage) in }).error({ (errorCode, waitTime) in }).send()
        }
        
        holdCallView(isOnHold: isOnHold)
        
        for audioTrack in RTCClient.mediaStream.audioTracks {
            audioTrack.isEnabled = !isOnHold
        }
       
        /*
        for videoTrack in RTCClient.mediaStream.videoTracks {
            videoTrack.isEnabled = !isOnHold
        }
        */
    }
    
    private func holdCallView(isOnHold: Bool){
        DispatchQueue.main.async {
            self.holdView.isHidden = !isOnHold
            if self.callType == .videoCalling {
                self.imgAvatar.isHidden = !isOnHold
            }
        }
    }
    
    private func answerCall(withDelay: Bool = false){
        stopSound()
        txtCallState.text = IGStringsManager.GlobalCommunicating.rawValue.localized
        manageView(stateAnswer: false)
        if withDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
                RTCClient.getInstance()?.answerCall()
            }
        } else {
            RTCClient.getInstance()?.answerCall()
        }
    }
    
    private func localCameraViewCustomize() {
        localCameraView.layer.cornerRadius = 10
        localCameraView.layer.borderWidth = 0.3
        localCameraView.layer.borderColor = UIColor.white.cgColor
        localCameraView.layer.masksToBounds = true
        localCameraView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
    
    private func buttonViewCustomize(button: UIButton, color: UIColor, imgName: String = ""){

        //button.removeUnderline()
        button.backgroundColor = color
        
        button.layer.shadowColor = ThemeManager.currentTheme.LabelGrayColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.shadowRadius = 0.1
        button.layer.shadowOpacity = 0.1
        
        button.layer.borderWidth = 0.5
        button.layer.borderColor = ThemeManager.currentTheme.LabelGrayColor.cgColor
        button.layer.masksToBounds = false
        button.layer.cornerRadius = button.frame.width / 2
    }
    
    private func incommingCall() {
        
        guard let connection = RTCClient.getInstance() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.incommingCall()
            }
            return
        }
        
        if connection.getPeerConnection() == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                RTCClient.getInstance()?.configure()
                self.incommingCall()
            }
            return
        }
        
        connection.startConnection(onPrepareConnection: { () -> Void in
            connection.sendRinging()
            connection.createAnswerForOfferReceived(withRemoteSDP: self.callSdp)
            guard let delegate = RTCClient.getInstance()?.callStateDelegate else {
                return
            }
            delegate.onStateChange(state: RTCClientConnectionState.IncommingCall)
        })
    }
    
    private func outgoingCall(displayName: String) {
        if #available(iOS 10.0, *), self.callType == .voiceCalling {
            CallManager.sharedInstance.startCall(phoneNumber: phoneNumber)
        }
        RTCClient.getInstance()?.callStateDelegate?.onStateChange(state: RTCClientConnectionState.Dialing)
        RTCClient.getInstance()?.startConnection(onPrepareConnection: { () -> Void in
            RTCClient.getInstance()?.makeOffer(userId: self.userId)
        })
    }
    
    private func setCallMode(callType: IGPSignalingOffer.IGPType, userInfo: IGRegisteredUser){
        
        if callType == .videoCalling {
            
            if #available(iOS 10.0, *) {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)), mode :AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.videoChat)))
                } catch {
                    print("error AVAudioSessionModeVideoChat")
                }
            }
            
            remoteCameraView.isHidden = false

            //localCameraView.isHidden = false
            //imgAvatar.isHidden = true
//            btnSwitchCamera.isEnabled = true
            txtiGap.text = IGStringsManager.VideoCall.rawValue.localized
            IGCallAudioManager.sharedInstance.setSpeaker(button: btnSpeaker)
            
        } else if callType == .voiceCalling {
            
            if #available(iOS 10.0, *) {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)), mode :AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.voiceChat)))
                } catch {
                    print("error AVAudioSessionModeVoiceChat")
                }
            }
            
            remoteCameraView.isHidden = true
            localCameraView.isHidden = true
            imgAvatar.isHidden = false
            txtiGap.text = IGStringsManager.VoiceCall.rawValue.localized
        }
        
        if let avatar = userInfo.avatar {
            lblIcon.isHidden = true
            if let avatarFile = avatar.file {
                imgAvatar.setAvatar(avatar: avatarFile)
                imgAvatarInner.setAvatar(avatar: avatarFile)
            }
        } else {
            lblIcon.isHidden = false
        }
    }
    
    private func manageView(stateAnswer: Bool){
        if stateAnswer {
            btnMute.isHidden = true
            btnSpeaker.isHidden = true
            btnChat.isHidden = true
            txtCallTime.isHidden = true

        } else {
            btnMute.isHidden = false
            btnSpeaker.isHidden = false
            btnChat.isHidden = false
            txtCallTime.isHidden = false
            btnAnswer.isHidden = true
            txtCallTime.isHidden = true
            
            btnCancel.snp.updateConstraints { (make) in
                make.bottom.equalTo(btnChat.snp.top).offset(-54)
                make.width.equalTo(70)
                make.height.equalTo(70)
                make.centerX.equalTo(self.view.snp.centerX)
            }
        }
    }
    
    private func enabelActions(enable: Bool = true){
        if enable {
            btnMute.isEnabled = true
            btnSpeaker.isEnabled = true
            btnChat.isEnabled = true
//            btnSwitchCamera.isEnabled = true
        } else {
            btnMute.isEnabled = false
            btnSpeaker.isEnabled = false
            btnChat.isEnabled = false
//            btnSwitchCamera.isEnabled = false
        }
    }
    
    private func changeBottomViewsVisibility(){
        viewNameHolder.isHidden = !(viewNameHolder.isHidden)

        if !callIsConnected || callType == .voiceCalling {return}
        
        bottomViewsIsHidden = !bottomViewsIsHidden
        
//        animateView(view: txtPowerediGap, isHidden: bottomViewsIsHidden)
    }
    
    private func animateView(view: UIView, isHidden: Bool){
        if isHidden {
            UIView.transition(with: view, duration: 0.5, options: .transitionFlipFromBottom, animations: {
                view.isHidden = isHidden
            }, completion: { (completed) in })
        } else {
            UIView.transition(with: view, duration: 0.5, options: .transitionFlipFromTop, animations: {
                view.isHidden = isHidden
            }, completion: { (completed) in })
        }
    }
    
    private func addRemoteVideoTrack(){
        guard let remote = self.remoteTrack else {
            return
        }
        
        if remoteTrackAdded { return }
        remoteTrackAdded = true
        
        DispatchQueue.main.async {
            self.imgAvatar.isHidden = true
            
            if self.remoteCameraView == nil {
                let videoView = RTCEAGLVideoView(frame: self.view.bounds)
                if let local = self.localCameraView {
                    self.view.insertSubview(videoView, belowSubview: local)
                } else {
                    self.view.addSubview(videoView)
                }
                self.remoteCameraView = videoView
            }
            remote.add(self.remoteCameraView!)
        }
    }
    
    private func muteManager(){
        if isMuteEnable {
            btnMute.setTitle("", for: UIControl.State.normal)
        } else {
            btnMute.setTitle("", for: UIControl.State.normal)
        }
        
        for audioTrack in RTCClient.mediaStream.audioTracks {
            audioTrack.isEnabled = isMuteEnable
        }
        
        isMuteEnable = !isMuteEnable
    }
    
    func onRemoteVideoCallStream(videoTrack: RTCVideoTrack) {
        self.remoteTrack = videoTrack
        if callIsConnected {
            addRemoteVideoTrack()
            
        }
    }
    
    func onLocalVideoCallStream(videoTrack: RTCVideoTrack) {
        DispatchQueue.main.async {
            if self.localCameraView == nil {
                let videoView = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width:100, height: 100))
                self.view.addSubview(videoView)
                self.localCameraView = videoView
            }
            videoTrack.add(self.localCameraView!)
        }
    }
    
    func onStateChange(state: RTCClientConnectionState) {
        IGCall.staticConnectionState = state
        DispatchQueue.main.async {
            switch state {
                
            case .Connecting:
                self.animateNameView(state: false)

                RTCClient.needNewInstance = false
                break
                
            case .Connected:
                self.animateNameView(state: true)
                self.addRemoteVideoTrack()
                
                IGCallEventListener.playHoldSound = false
                self.txtCallTime.isHidden = false
                self.txtCallState.text = IGStringsManager.Connected.rawValue.localized
                
                if !self.callIsConnected {
                    self.callIsConnected = true
                    self.playSound(sound: "igap_connect")
                    
                    if self.callType == .voiceCalling {
                        IGHelperTracker.shared.sendTracker(trackerTag: IGHelperTracker.shared.TRACKER_VOICE_CALL_CONNECTED)
                    } else if self.callType == .videoCalling {
                        IGHelperTracker.shared.sendTracker(trackerTag: IGHelperTracker.shared.TRACKER_VIDEO_CALL_CONNECTED)
                    }
                }
                
                do {
                    if self.callType == .videoCalling {
                        if #available(iOS 10.0, *) {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)), mode :AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.videoChat)))
                                self.lblIcon.isHidden = true
                                self.imgAvatarInner.isHidden = true
                                self.imgAvatarView.isHidden = true
                                self.viewTransparent.isHidden = true

                            } catch {
                                print("error AVAudioSessionModeVideoChat")
                            }
                        }
                    } else {
                        if #available(iOS 10.0, *) {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)), mode :AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.voiceChat)))
                            } catch {
                                print("error AVAudioSessionModeVideoChat")
                            }
                        }
                    }
                    
                    if #available(iOS 10.0, *) {
                        try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)),mode: AVAudioSession.Mode.default , options: .allowBluetooth)
                    } else {
                        // Fallback on earlier versions
                    }
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    // if is videoCalling && current btn title state is speaker enable && not paired bluetooth device THEN set current audio state to speaker
                    if self.callType == .videoCalling && self.btnSpeaker.titleLabel?.text == "" && !IGCallAudioManager.sharedInstance.hasBluetoothDevice() {
                        try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                    }
                    IGCallAudioManager.sharedInstance.fetchAudioState(btnAudioState: self.btnSpeaker)
                } catch let error {
                    print(error.localizedDescription)
                }
                if self.callTimer == nil {
                    self.callTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimerLabel), userInfo: nil, repeats: true)
                    self.callTimer?.fire()
                }
                break
                
            case .Finished, .Disconnected, .Accepted:
                self.animateNameView(state: false)
                self.txtCallState.text = IGStringsManager.Disconnected.rawValue.localized
                self.playSound(sound: "igap_disconnect")
                self.dismmis()
                RTCClient.getInstance(justReturn: true)?.callStateDelegate = nil
                break
                
            case .Missed:
                self.txtCallState.text = IGStringsManager.Missed.rawValue.localized
                self.dismmis()
                break
                
            case .NotAnswered:
                self.txtCallState.text = IGStringsManager.UnAnsweredCall.rawValue.localized
                self.playSound(sound: "igap_noresponse")
                self.dismmis()
                break
                
            case .Rejected:
                self.txtCallState.text = IGStringsManager.Reject.rawValue.localized
                self.playSound(sound: "igap_disconnect")
                self.dismmis()
                break
                
            case .TooLong:
                self.txtCallState.text = ""
                self.playSound(sound: "igap_disconnect")
                self.dismmis()
                break
                
            case .Failed:
                self.txtCallState.text = IGStringsManager.Failed.rawValue.localized
                self.playSound(sound: "igap_noresponse")
                self.dismmis()
                break
                
            case .Unavailable:
                self.txtCallState.text = ""
                self.playSound(sound: "igap_noresponse")
                self.dismmis()
                break
                
            case .IncommingCall:
                self.txtCallState.text = IGStringsManager.IncomingCall.rawValue.localized
                if self.callType == .videoCalling {
                    self.playSound(sound: "tone", repeatEnable: true)
                }
                break
                
            case .Ringing:
                self.animateNameView(state: false)
                self.txtCallState.text = IGStringsManager.Ringing.rawValue.localized
                self.playSound(sound: "igap_ringing", repeatEnable: true)
                break
                
            case .Dialing:
                self.animateNameView(state: false)
                self.txtCallState.text = IGStringsManager.Dialing.rawValue.localized
                self.playSound(sound: "igap_signaling", repeatEnable: true)
                break
                
            case .signalingOfferForbiddenYouAreTalkingWithYourOtherDevices:
                
                self.animateNameView(state: false)

                IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.ErrorTalkingWithOther.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized)
                break
                
            case .signalingOfferForbiddenTheUserIsInConversation:
                self.animateNameView(state: false)

                IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.ErrorUserInConversation.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized,cancel:  {
                    self.dismmis()
                })

                break
                
            case .signalingOfferForbiddenDialedNumberIsNotActive:
                self.animateNameView(state: false)

                IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.ErrorDialedNumIsNotActive.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized,cancel:  {
                    self.dismmis()
                })
                break
                
            case .signalingOfferForbiddenUserIsBlocked:
                self.animateNameView(state: false)

                IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.ErrorUserIsBlocked.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized,cancel:  {
                    self.dismmis()
                })
                break
                
            case .signalingOfferForbiddenIsNotAllowedToCommunicate:
                self.animateNameView(state: false)

                self.playSound(sound: "igap_disconnect")
                IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: IGStringsManager.GlobalWarning.rawValue.localized, showIconView: true, showDoneButton: false, showCancelButton: true, message: IGStringsManager.ErrorAllowedNotToCommunicate.rawValue.localized, cancelText: IGStringsManager.GlobalClose.rawValue.localized,cancel:  {
                    self.dismmis()
                })
                break
                
            default:
                break
            }
        }
    }
    func animateNameView(state : Bool) {
        if state {
            txtCallTime.textColor = .black
            txtCallState.textColor = .black
            txtCallTime.textColor = .black

            viewNameCenterConstraint.constant = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                self.viewNameHolder.backgroundColor = UIColor.white.withAlphaComponent(0.2)

            }

        } else {
            txtCallTime.textColor = ThemeManager.currentTheme.LabelColor
            txtCallState.textColor = ThemeManager.currentTheme.LabelColor
            txtCallTime.textColor = ThemeManager.currentTheme.LabelColor
            viewNameHolder.backgroundColor = .clear

            viewNameCenterConstraint.constant = imgAvatarView.bounds.height / 3
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()

            }

        }
        
    }
    func returnToCall() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func updateTimerLabel() {
        recordedTime += 1
        let minute = String(format: "%02d", Int(recordedTime/60)).inLocalizedLanguage()
        let seconds = String(format: "%02d", Int(recordedTime%60)).inLocalizedLanguage()

        self.txtCallTime.text = minute + ":" + seconds
    }
    
    private func dismmis() {
        if #available(iOS 10.0, *) {
            CallManager.sharedInstance.endCall()
        }
        
        RTCClient.getInstance(justReturn: true)?.disconnect()
        IGCall.callPageIsEnable = false
        IGCallEventListener.playHoldSound = false
        callIsConnected = false
        
        if let timer = callTimer {
            timer.invalidate()
        }
        
        if IGCall.sendLeaveRequest {
            IGCall.sendLeaveRequest = false
            sendLeaveCall()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.getLatestCallLog()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stopSound()
            self.dismiss(animated: true, completion: nil)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func sendLeaveCall(){
        IGSignalingLeaveRequest.Generator.generate().success({ (protoResponse) in
        }).error ({ (errorCode, waitTime) in
            switch errorCode {
            case .timeout:
                self.sendLeaveCall()
                break
            default:
                break
            }
        }).send()
    }
    
    private func getLatestCallLog(){
        IGSignalingGetLogRequest.Generator.generate(offset: Int32(0), limit: 1, mode: .all).success { (responseProtoMessage) in
            
            if let logResponse = responseProtoMessage as? IGPSignalingGetLogResponse {
                let _ = IGSignalingGetLogRequest.Handler.interpret(response: logResponse)
            }
            
            }.error({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    self.getLatestCallLog()
                    break
                default:
                    break
                }
            }).send()
    }
    
    
    func playSound(sound: String, repeatEnable: Bool = false) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: "mp3") else { return }
        
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: AVAudioSession.Mode.default )
            } else {
                // Fallback on earlier versions
            }
            try AVAudioSession.sharedInstance().setActive(true)
        
            stopSound()
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            if repeatEnable {
                player.numberOfLoops = -1
            }
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound(){
        if player != nil {
            player?.stop()
        }
    }
    
    // override this method for enable landscape orientation
    @objc func canRotate() -> Void {}
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if latestLocalVideoSize != nil {
            manageLocalVideoView(size: latestLocalVideoSize)
        }
        if latestRemoteVideoSize != nil {
            manageRemoteVideoView(size: latestRemoteVideoSize)
        }
    }
    
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        
        if videoView.viewWithTag(1) != nil { //localCameraView frame
            latestLocalVideoSize = size
            manageLocalVideoView(size: size)
            
        } else { // remoteCameraView frame
            latestRemoteVideoSize = size
            manageRemoteVideoView(size: size)
        }
    }
    
    private func manageRemoteVideoView(size: CGSize){
        
        let videoWidth = size.width
        let videoHeight = size.height
        
        var finalWidth: CGFloat = 0
        var finalHeight: CGFloat = 0
        var videoViewLeft: Double = 0
        var videoViewTop: Double = 0
        
        var ratio : CGFloat = mainWidth / videoWidth
        
        if UIDevice.current.orientation.isLandscape {
            
            ratio = mainWidth / videoHeight
            
            finalWidth = videoWidth * ratio
            finalHeight = mainWidth
            
            videoViewLeft = Double((mainHeight - finalWidth) / 2)
            videoViewTop = Double((mainWidth - finalHeight) / 2)
            
        } else {
            
            finalWidth = mainWidth
            finalHeight = videoHeight * ratio
            
            videoViewLeft = Double((mainWidth - finalWidth) / 2)
            videoViewTop = Double((mainHeight - finalHeight) / 2)
        }
        
        self.remoteCameraView.frame = CGRect(
            x: CGFloat(videoViewLeft),
            y: CGFloat(videoViewTop),
            width: finalWidth,
            height: finalHeight
        )
    }
    
    private func manageLocalVideoView(size: CGSize){
        
        var mainWidth : CGFloat = 100
        var videoViewTop: Double = Double(40)
        
        if size.width > size.height {
            mainWidth = 150
            videoViewTop = Double(20)
        }
        
        let videoWidth = size.width
        let videoHeight = size.height
        
        var finalWidth : CGFloat = 0
        var finalHeight : CGFloat = 0
        
        let ratio : CGFloat = mainWidth / videoWidth
        
        finalWidth = mainWidth
        finalHeight = videoHeight * ratio
        
        let videoViewLeft: Double = Double((self.mainView.frame.width - (finalWidth + 20)))
        
        self.localCameraView.frame = CGRect(
            x: CGFloat(videoViewLeft),
            y: CGFloat(videoViewTop),
            width: finalWidth,
            height: finalHeight
        )
        
        if localCameraView.isHidden {
            localCameraView.isHidden = false
        }
    }
    
    /***************************** Call Manager Callbacks *****************************/
    
    func callDidAnswer() {
        answerCall(withDelay: true)
    }
    
    func callDidEnd() {
        dismmis()
    }
    
    func callDidHold(isOnHold: Bool) {
        hold(isOnHold: isOnHold)
    }
    
    func callDidFail() {
        dismmis()
    }
    
    func callDidMute(isMuted: Bool) {
        muteManager()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
