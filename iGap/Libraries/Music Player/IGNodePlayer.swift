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
import AVFoundation
import MediaPlayer
import SwiftEventBus
import SwiftProtobuf
import RealmSwift
import AsyncDisplayKit

class IGNodePlayer {
    
    static let shared = IGNodePlayer()
    
    var btnPlayPause: ASButtonNode!
    var slider: UISlider!
    var timer: ASTextNode!
    var flag: Bool = false
    var roomMessage: IGRoomMessage?
    var attachment: IGFile?
    var attachmentStringTime: String!
    var attachmentFloatTime: Float!
    var attachmentTimeScale: CMTimeScale!
    
    var player = IGMusicPlayer.sharedPlayer
    private var playerWatcherIndex = 0
    private var latestTimeValue: String?
    private var latestSliderValue: Float?
    private var latestButtonValue: String!
    private var singerName : String! = IGStringsManager.UnknownArtist.rawValue.localized
    private var songName : String! = IGStringsManager.VoiceMessage.rawValue.localized
    private var songTime : Float! = 0
    var currentTimeOfSong : Float! = 0
    ////audio player custom vars
    var room : IGRoom!
    var sharedMediaFilter : IGSharedMediaFilter? = .audio
    var shareMediaMessage : Results<IGRoomMessage>!
    var notificationToken: NotificationToken?
    var isFetchingFiles: Bool = false

    /**
     * @param attachment media info for make player session
     * @param justUpdate if set true player view will be update with current state otherwise will be started new player with attachment param
     */
    func startPlayer(btnPlayPause: ASButtonNode? = nil, slider: UISlider? = nil, timer: ASTextNode? = nil, roomMessage: IGRoomMessage, justUpdate: Bool = false,room: IGRoom? = nil,isfromBottomPlayer: Bool? = nil){
        
        DispatchQueue.main.async {[weak self] in
            guard let sSelf = self else {
                return
            }
        
            sSelf.room = room
            sSelf.setupRemoteTransportControls()
    //        setupNowPlaying()
            sSelf.fetchMusicList(room : sSelf.room)
            if isfromBottomPlayer != nil {
                if isfromBottomPlayer! {
                    if justUpdate {
                        if sSelf.roomMessage?.id == roomMessage.id {
                        }
                    } else {
                        /* if is new file reset previous if exist reset otherwise manage play/pause for current player */
                        if sSelf.roomMessage?.id != roomMessage.id {
                            sSelf.resetOldSession()
                            sSelf.roomMessage = roomMessage
                            sSelf.attachment = roomMessage.getFinalMessage().attachment
                            sSelf.fetchAttachmentTime()
                            sSelf.latestSliderValue = 0.0
                            sSelf.playerWatcherIndex = sSelf.player.addWatcher(sSelf)
                            sSelf.playMedia()
                        } else {
    //                        resetOldSession()
                            sSelf.updatePlayPauseState()
                        }
                    }
                }
            }
            else {
                if justUpdate {
                    if sSelf.roomMessage != nil && !sSelf.roomMessage!.isInvalidated && sSelf.roomMessage!.id == roomMessage.id {
    //                    btnPlayPause!.setTitle(latestButtonValue, for: UIControl.State.normal)
                        let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

                        IGGlobal.makeAsyncButton(for: btnPlayPause!, with: sSelf.latestButtonValue, textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)
                        
                        slider!.value = sSelf.latestSliderValue ?? 0
    //                    timer!.text = latestTimeValue
                        IGGlobal.makeAsyncText(for: timer!, with: sSelf.latestTimeValue?.inLocalizedLanguage() ?? "", textColor: UIColor.darkGray, size: 13, font: .igapFont, alignment: .center)
                        
                        
                        sSelf.btnPlayPause = btnPlayPause
                        sSelf.slider = slider
                        sSelf.slider.maximumValue = sSelf.attachmentFloatTime
                        sSelf.timer = timer
                        sSelf.removeGestureRecognizer()
                        sSelf.addGestureRecognizer()
                    }
                } else {
                    /* if is new file reset previous if exist reset otherwise manage play/pause for current player */
                    if sSelf.roomMessage?.id != roomMessage.id {
                        sSelf.resetOldSession()
                        sSelf.btnPlayPause = btnPlayPause
                        sSelf.slider = slider
                        sSelf.timer = timer
                        sSelf.roomMessage = roomMessage
                        sSelf.attachment = roomMessage.getFinalMessage().attachment
                        sSelf.addGestureRecognizer()
                        sSelf.fetchAttachmentTime()
                        sSelf.slider.setThumbImage(UIImage(named: "IG_Message_Cell_Player_Slider_Thumb"), for: .normal)
                        slider!.value = 0.0
                        sSelf.latestSliderValue = 0.0
                        slider!.maximumValue = sSelf.attachmentFloatTime
                        sSelf.playerWatcherIndex = sSelf.player.addWatcher(sSelf)
                        sSelf.playMedia()
                    } else {
                        sSelf.updatePlayPauseState()
                    }
                }
            }

            
        }
    }
    
    /** if another voice or audio is playing remove old valus and reset slider and timer */
    private func resetOldSession(){
        if btnPlayPause != nil {
            self.latestButtonValue = ""
//            self.btnPlayPause.setTitle("", for: UIControl.State.normal) // play icon
            let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

            IGGlobal.makeAsyncButton(for: btnPlayPause, with: "", textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)
            self.slider.value = 0.0
            latestSliderValue = 0.0
            updateTimer(currentTime: Float(0))
            if player.checkPlayerControlStatus() { // is playing
                self.pauseMedia()

            }
            self.player.removeItemsFromList()
            
            removeGestureRecognizer()
        }
    }
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            self.playMedia()
            SwiftEventBus.post(EventBusManager.changePlayState,sender: true)

                return .success
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
                self.pauseMedia()
            SwiftEventBus.post(EventBusManager.changePlayState,sender: false)

                return .success
        }
    }
    private func fetchMusicList(room : IGRoom!) {
        
//        if let thisRoom = room {
//            let messagePredicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND isFromSharedMedia == true AND typeRaw == 5 OR typeRaw == 6", thisRoom.id)
//            shareMediaMessage =  try! Realm().objects(IGRoomMessage.self).filter(messagePredicate)
//            self.notificationToken = shareMediaMessage.observe { (changes: RealmCollectionChange) in
//                switch changes {
//                case .initial:
//
//                    break
//                case .update(_, _, _, _):
//                    // Query messages have changed, so apply them to the TableView
//
//                    break
//                case .error(let err):
//                    // An error occurred while opening the Realm file on the background worker thread
//                    fatalError("\(err)")
//                    break
//                }
//            }
//        }
        
        
    }
    private func fetchAttachmentTime(){
        
        let path = attachment!.localUrl
        let asset = AVURLAsset(url: path!)
        let playerItem = AVPlayerItem(asset: asset)
        let timeScale = playerItem.asset.duration.timescale
        let time = (CMTimeGetSeconds(asset.duration))
        let timeInt = Int(time)
        songTime = Float(time)
        let remainingSeconds = timeInt%60
        let remainingMiuntes = timeInt/60
        //fetching song metadata
        setupNowPlaying(asset: asset,file : attachment!)
        IGGlobal.currentMusic = attachment
        //end
        attachmentStringTime = "\(remainingMiuntes):\(remainingSeconds)"
        attachmentFloatTime = Float(time)
        attachmentTimeScale = timeScale
        SwiftEventBus.post(EventBusManager.updateLabelsData)

    }
    func setupNowPlaying(asset: AVURLAsset,file : IGFile!) {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        let playerItem = AVPlayerItem(asset: asset)
        //metaData
        let metadataList = playerItem.asset.commonMetadata
        var hasSingerName : Bool = false
        var hasSongName : Bool = false
        if IGGlobal.isVoice {
            songName = IGStringsManager.VoiceMessage.rawValue.localized
            if roomMessage?.authorUser != nil {
                singerName = roomMessage?.authorUser?.user?.displayName
                IGGlobal.topBarSongSinger = singerName
                nowPlayingInfo[MPMediaItemPropertyTitle] = IGStringsManager.VoiceMessage.rawValue.localized + " " + singerName

            }
            
        } else {
            for item in metadataList {
                if item.commonKey!.rawValue == "title" {
                    songName = item.stringValue!
                    IGGlobal.topBarSongName = songName
                    hasSongName = true
                    nowPlayingInfo[MPMediaItemPropertyTitle] = songName
                }
                if item.commonKey!.rawValue == "artist" {
                    singerName = item.stringValue!
                    IGGlobal.topBarSongSinger = singerName
                    hasSingerName = true
                    nowPlayingInfo[MPMediaItemPropertyArtist] = singerName

                }
            }
            if !hasSingerName {
                singerName = IGStringsManager.UnknownArtist.rawValue.localized
                IGGlobal.topBarSongSinger = singerName
                nowPlayingInfo[MPMediaItemPropertyArtist] = singerName


            }
            if !hasSongName {
                if let sn =  attachment?.name {
                    songName = sn
                    IGGlobal.topBarSongName = songName
                    nowPlayingInfo[MPMediaItemPropertyTitle] = songName

                    
                } else {
                    songName = IGStringsManager.UnknownAudio.rawValue.localized
                    IGGlobal.topBarSongName = songName
                    nowPlayingInfo[MPMediaItemPropertyTitle] = songName

                }
            }
        }

        //
        let artworkItems = AVMetadataItem.metadataItems(from: metadataList, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierArtwork)

        if let artworkItem = artworkItems.first {
            // Coerce the value to an NSData using its dataValue property
            if let imageData = artworkItem.dataValue {
                let image = UIImage(data: imageData)
                nowPlayingInfo[MPMediaItemPropertyArtwork] =
                    MPMediaItemArtwork(boundsSize: image!.size) { size in
                        return image!
                }

                // process image
            } else {
                let avatarView : UIImageView = UIImageView()
                avatarView.setThumbnail(for: file)
                

                if let image = avatarView.image {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] =
                        MPMediaItemArtwork(boundsSize: image.size) { size in
                            return image
                    }
                }
            }
        }
        
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerItem.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateTimer(currentTime: Float){
        let valueInt = Int(currentTime)
        let remainingSeconds = valueInt%60
        let remainingMiuntes = valueInt/60
        let finalValue = "\(remainingMiuntes):\(remainingSeconds) / \(attachmentStringTime ?? "00:00")".inLocalizedLanguage()
//        timer.text = finalValue
        IGGlobal.makeAsyncText(for: timer, with: finalValue, textColor: .darkGray, size: 13, font: .igapFont, alignment: .center)
        latestTimeValue = finalValue
    }
    
    func updateSliderValue() {
        if flag == false {
            slider.isContinuous = true
            let currentTime = player.getCurrentTime()
            let currentTimeFloat = (CMTimeGetSeconds(currentTime))
            let currentValue = Float(currentTimeFloat)
            SwiftEventBus.post(EventBusManager.updateMediaTimer,sender: currentValue)

            if currentValue <=  slider.maximumValue {
                slider.setValue(Float(currentTimeFloat),animated: true)
                updateTimer(currentTime: Float((CMTimeGetSeconds(currentTime))))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateSliderValue()
                }
            }
            
            //Hint: sometimes value of 'currentValue' is nan after reach to end of media
            if currentValue >= slider.maximumValue || currentValue.isNaN {
                self.slider.value = 0.0
                latestSliderValue = 0.0
                IGGlobal.songState = .ended
                self.didTapOnbtnPlayPause(btnPlayPause)
                self.player.removeItemsFromList()
            }
        }
    }
    
    private func sliderValueChanged() {
        latestSliderValue = slider.value
        let currentTime = player.getCurrentTime()
        let currentTimeFloat = (CMTimeGetSeconds(currentTime))

        player.seekToTime(value: CMTimeMakeWithSeconds(Float64(slider.value), preferredTimescale: attachmentTimeScale))
        flag = false
        updateSliderValue()
    }
    func updateSLider(value: Float,sliderBottom: UISlider) {
        latestSliderValue = value
        player.seekToTime(value: CMTimeMakeWithSeconds(Float64(value), preferredTimescale: attachmentTimeScale))
        flag = false
        updateSliderValueToTime(slideerBottom : sliderBottom)

    }
    
    private func updateSliderValueToTime(slideerBottom : UISlider) {
        if flag == false {
            slider.isContinuous = true
            slideerBottom.isContinuous = true
            let currentTime = player.getCurrentTime()
            let currentTimeFloat = (CMTimeGetSeconds(currentTime))
            let currentValue = Float(currentTimeFloat)
            SwiftEventBus.post(EventBusManager.updateMediaTimer,sender: currentValue)

            if currentValue <=  slider.maximumValue {
                slider.setValue(Float(currentTimeFloat),animated: true)
                slideerBottom.setValue(Float(currentTimeFloat),animated: true)
                updateTimer(currentTime: Float((CMTimeGetSeconds(currentTime))))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateSliderValueToTime(slideerBottom: slideerBottom)
                }
            }
            
            //Hint: sometimes value of 'currentValue' is nan after reach to end of media
            if currentValue >= slider.maximumValue || currentValue.isNaN {
                self.slider.value = 0.0
                latestSliderValue = 0.0
                IGGlobal.songState = .ended
                self.didTapOnbtnPlayPause(btnPlayPause)
                self.player.removeItemsFromList()
            }
        }
    }
    
    private func playMedia(){
        if let file = attachment {
            
            IGGlobal.songState = .playing
            let files = [file]
            self.latestButtonValue = ""
            let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

            IGGlobal.makeAsyncButton(for: self.btnPlayPause, with: "", textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)
            
            
//            UIView.transition(with: btnPlayPause,duration: 0.3, options: .transitionFlipFromTop, animations: {
//                self.latestButtonValue = ""
//                self.btnPlayPause.setTitle("", for: UIControl.State.normal) // pause icon
//            },completion: nil)
            
            player.play(index: 0, from: files)
            flag = false
            updateSliderValue()
            if !(IGGlobal.isVoice) {

                if !(IGGlobal.isAlreadyOpen) {
                    SwiftEventBus.post(EventBusManager.showTopMusicPlayer,sender: MusicFile(songName: songName, singerName: singerName, songTime: songTime, currentTime: 0.0))
                    IGGlobal.isAlreadyOpen = !IGGlobal.isAlreadyOpen
                }
            }
        }
    }
    
    private func pauseMedia(){
        IGGlobal.songState = .paused
        
        self.latestButtonValue = ""
        let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

        IGGlobal.makeAsyncButton(for: self.btnPlayPause, with: "", textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)
        
        
//        UIView.transition(with: btnPlayPause,duration: 0.3, options: .transitionFlipFromTop, animations: {
//            self.latestButtonValue = ""
//            self.btnPlayPause.setTitle("", for: UIControl.State.normal) // play icon
//        },completion: nil)

        player.pause()
        flag = true
    }
    func stopMedia(){
        
        self.latestButtonValue = ""
        let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

        IGGlobal.makeAsyncButton(for: self.btnPlayPause, with: "", textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)
        
        
//        UIView.transition(with: btnPlayPause,duration: 0.3, options: .transitionFlipFromTop, animations: {
//            self.latestButtonValue = ""
//            self.btnPlayPause.setTitle("", for: UIControl.State.normal) // play icon
//        },completion: nil)

        player.removeItemsFromList()
        flag = false
    }
    func pauseMusic(){
        IGGlobal.songState = .paused
        
        self.latestButtonValue = ""
        let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

        IGGlobal.makeAsyncButton(for: self.btnPlayPause, with: "", textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)
        
        
        
//        UIView.transition(with: btnPlayPause,duration: 0.3, options: .transitionFlipFromTop, animations: {
//            self.latestButtonValue = ""
//            self.btnPlayPause.setTitle("", for: UIControl.State.normal) // play icon
//        },completion: nil)
        SwiftEventBus.post(EventBusManager.changePlayState,sender: false)

        player.pause()
        flag = true

    }
    func playMusic(){
        if let file = attachment {
            IGGlobal.songState = .playing
            let files = [file]
            SwiftEventBus.post(EventBusManager.changePlayState,sender: true)
            
            self.latestButtonValue = ""
            let tmpcolor = IGGlobal.makeCustomColor(OtherThemesColor: ThemeManager.currentTheme.timeColor,BlackThemeColor: .white)

            IGGlobal.makeAsyncButton(for: self.btnPlayPause, with: "", textColor: tmpcolor, size: 35, font: .fontIcon, alignment: .center)

//            UIView.transition(with: btnPlayPause,duration: 0.3, options: .transitionFlipFromTop, animations: {
//                self.latestButtonValue = ""
//                self.btnPlayPause.setTitle("", for: UIControl.State.normal) // pause icon
//            },completion: nil)

            player.play(index: 0, from: files)
            flag = false
            updateSliderValue()


        }
    }

    private func addGestureRecognizer(){
        slider.addTarget(self, action: #selector(sliderTouchUpInside(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchUpOutside(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    private func removeGestureRecognizer(){
        slider.removeTarget(self, action: #selector(sliderTouchUpInside(_:)), for: .touchUpInside)
        slider.removeTarget(self, action: #selector(sliderTouchUpOutside(_:)), for: .touchUpOutside)
        slider.removeTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
        slider.removeTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    
    /*************************************************************************/
    /**************************** Gesture Manager ****************************/
    
    @objc func sliderTouchUpInside(_ sender: UISlider) {
        sliderValueChanged()
    }
    @objc func sliderTouchUpOutside(_ sender: UISlider) {
        sliderValueChanged()
    }
    @objc func sliderTouchDown(_ sender: UISlider) {
        flag = true
    }
    @objc func sliderValueChanged(_ sender: UISlider) {
        flag = true
        latestSliderValue = slider.value
        updateTimer(currentTime: slider.value)
    }

    
    @objc func didTapOnbtnPlayPause(_ sender: ASButtonNode) {
        let isPlaying = player.checkPlayerControlStatus()
        if isPlaying {
            self.pauseMedia()
            SwiftEventBus.post(EventBusManager.changePlayState,sender: false)

        } else {
            self.playMedia()
            SwiftEventBus.post(EventBusManager.changePlayState,sender: true)
        }
    }
    func updatePlayPauseState() {
        let isPlaying = player.checkPlayerControlStatus()
        if isPlaying {
            self.pauseMedia()
            SwiftEventBus.post(EventBusManager.changePlayState,sender: false)

        } else {
            self.playMedia()
            SwiftEventBus.post(EventBusManager.changePlayState,sender: true)
        }
    }
}

extension IGNodePlayer: IGMusicPlayerDelegate {
    func player(_ player:IGMusicPlayer, didStartPlaying item:AVPlayerItem) {
        
    }
    
    func player(_ player:IGMusicPlayer, didPausePlaying item:AVPlayerItem) {
        
    }
    
    func player(_ player:IGMusicPlayer, didStopPlaying item:AVPlayerItem) {
        
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromOptionalAVMetadataKey(_ input: AVMetadataKey?) -> String? {
    guard let input = input else { return nil }
    return input.rawValue
}

