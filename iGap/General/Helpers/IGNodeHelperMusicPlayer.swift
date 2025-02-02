/*
* This is the source code of iGap for iOS
* It is licensed under GNU AGPL v3.0
* You should have received a copy of the license in this archive (see LICENSE).
* Copyright © 2017 , iGap - www.iGap.net
* iGap Messenger | Free, Fast and Secure instant messaging application
* The idea of the Kianiranian STDG - www.kianiranian.com
* All rights reserved.
*/

import IGProtoBuff
import RealmSwift
import UIKit
import SwiftEventBus

// IMPORTANT TODO - convert current class to builder


class IGNodeHelperMusicPlayer {
    enum MusicCurrentState : Int {
        case Playing = 0
        case Stoped = 1
    }
    var room : IGRoom!
    var progressBarTimer: Timer!
    private var isRunning = true
    var valueToAdd: Float! = 0.0
    var currentMusicTime: Float! = 0.0
    var musicTotalTime: Float! = 0
    let window = UIApplication.shared.keyWindow
    
    private var actionClose: (() -> Void)?
    private var actionPlay: (() -> Void)?
    private var actionPause: (() -> Void)?
    private var actionNextMusic: (() -> Void)?
    private var actionPreviousMusic: (() -> Void)?
    private var actionShuffleMusics: (() -> Void)?
    private var actionRepeatMusics: (() -> Void)?
    private var actionChangeTime: (() -> Void)?
    
    static let shared = IGNodeHelperMusicPlayer()
    //    var progressView : UIProgressView!
    var btnPlay : UIButton!
    var topView : UIView!
    var bgView : UIView!
    
    private init() {}
    
    
    ///Top Music Player tobe shown  in Room List and Message page
    ///
    func showTestVIew() -> UIView {
        let v = UIView()
        v.backgroundColor = .blue
        return v
    }
    func showTopMusicPlayer(view: UIViewController? = nil,constraintView: UIView? = nil,constraintStackView: UIStackView? = nil, close: (() -> Void)? = nil, btnPlayPause: (() -> Void)? = nil,songTime : Float! = 0.0,singerName: String? = nil,songName: String? = nil) -> UIView {
        var alertView = view
        if alertView == nil {
            alertView = UIApplication.topViewController()
        }
        
        //        if self.bgView == nil {
        if self.bgView != nil {
            removeTopPlayer()
        }
            
        self.bgView = self.createMainView()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didBGViewGotTap))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.bgView.addGestureRecognizer(tapGestureRecognizer)
        
        
        ///add play pause button to it's superView
        let btn = UIButton()
        self.bgView.addSubview(btn)
        self.createPausePlayButton(btn: btn, view: self.bgView)
        btn.addTarget(self, action: #selector(self.buttonAction(_:)), for: .touchUpInside)
        
        
        ///add close button to it's superView
        let CloseButton = UIButton()
        self.bgView.addSubview(CloseButton)
        self.createCloseButton(btn: CloseButton, view: self.bgView)
        CloseButton.addTarget(self, action: #selector(self.didTapOnClose(_:)), for: .touchUpInside)
        
        
        //labels
        let lblSinger = UILabel()
        let lblSong = UILabel()
        self.bgView.addSubview(lblSong)
        self.bgView.addSubview(lblSinger)
        lblSinger.text = singerName ?? IGStringsManager.UnknownArtist.rawValue.localized
        lblSong.text = songName ?? IGStringsManager.UnknownAudio.rawValue.localized
        
        musicTotalTime = songTime
        
        self.createLabelsInPlayer(songName: lblSong, singerName: lblSinger, view: self.bgView)
        self.actionClose = close
        
        
        
        
        ////borders
        let borderTop = UIView()///border Top
        let borderBottom = UIView()///border Bottom
        self.bgView.addSubview(borderTop)
        self.bgView.addSubview(borderBottom)
        
        self.creatBorders(topBorder: borderTop, bottomBorder: borderBottom, view: self.bgView)
        
        
        
        //progressView
        let pv = UIProgressView()
        self.bgView.addSubview(pv)
        
        self.createProgressView(pv: pv, view: self.bgView,bottomBorder: borderBottom)
        //            self.progressBarTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateProgressView), userInfo: nil, repeats: true)
        
        
        SwiftEventBus.onMainThread(self, name: EventBusManager.updateMediaTimer) { result in
//            print(result?.object as! Float)
            self.updateProgressView(currentTime: result?.object as! Float, progressView: pv)
        }
        
        SwiftEventBus.onMainThread(self, name: EventBusManager.changePlayState) { result in
//            print(result?.object as! Bool)
            self.updateButtonState(state: result?.object as! Bool,btn: btn)
        }
        SwiftEventBus.onMainThread(self, name: EventBusManager.updateLabelsData) { result in
            //            print(result?.object as! Bool)
            self.room = result?.object as! IGRoom?
            self.updateLabelsData(singerName: IGGlobal.topBarSongSinger,songName: IGGlobal.topBarSongName)
        }
        return self.bgView
    }
    
    @objc func updateLabelsData(singerName: String!,songName: String!) {
        let labels = self.bgView.subviews.flatMap { $0 as? UILabel }
        for label in labels {
            if label.tag == 707 { //songName
                label.text = songName ?? IGStringsManager.UnknownArtist.rawValue.localized
            }
            if label.tag == 708 { //singerName
                label.text = singerName ?? IGStringsManager.UnknownAudio.rawValue.localized

            }
        }
    }
    func showBottomPanPlayer(view: UIViewController? = nil,songList:[MusicFile]? = nil) {//}-> UIView {
        var alertView = view
        if alertView == nil {
            alertView = UIApplication.topViewController()
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "MusicPlayer", bundle: nil)
        let MP = storyboard.instantiateViewController(withIdentifier: "IGNodeMusicPlayerTableViewController") as! IGNodeMusicPlayerTableViewController
        MP.room = self.room
        alertView!.presentPanModal(MP)
//        return UIView()
    }
    func removeTopPlayer() {
//        SwiftEventBus.post(EventBusManager.hideTopMusicPlayer)
//            currentMusicTime = 0
//            self.bgView.removeFromSuperview()
//            for subview in self.bgView.subviews {
//                subview.removeFromSuperview()
//            }
    }
    //MARK: - Development funcs
    
    @objc func didTapOnClose(_ sender:UIButton!) {
           IGGlobal.isAlreadyOpen = false
           if sender.superview!.tag == 404 {
               self.removeMainViewFromSuperView(bgView: sender.superview)
           }
       }
    @objc func didBGViewGotTap() {
//        print("BGVIEW GOT TAP")
        self.showBottomPanPlayer()
        switch IGGlobal.songState {
        case .ended :
            SwiftEventBus.post(EventBusManager.updateBottomPlayerButtonsState,sender: false)
            break
        case .playing :
            SwiftEventBus.post(EventBusManager.updateBottomPlayerButtonsState,sender: true)
            break
        case .paused :
            SwiftEventBus.post(EventBusManager.updateBottomPlayerButtonsState,sender: false)
            break
        default:
            break
        }


    }
    private func updateButtonState(state : Bool! , btn :UIButton!) {
        switch IGGlobal.songState {
        case .ended :
            btn.setTitle("", for: .normal)
            SwiftEventBus.post(EventBusManager.updateBottomPlayerButtonsState,sender: false)

            break
        case .playing :
            SwiftEventBus.post(EventBusManager.updateBottomPlayerButtonsState,sender: true)
            btn.setTitle("", for: .normal)
            break
        case .paused :
            SwiftEventBus.post(EventBusManager.updateBottomPlayerButtonsState,sender: false)
            btn.setTitle("", for: .normal)
            break
        default:
            break
        }
    }
    @objc func buttonAction(_ sender:UIButton!)
    {
        UIView.transition(with: sender,duration: 0.3, options: .transitionFlipFromTop, animations: {
            if  !(IGGlobal.isPaused){
                sender.setTitle("", for: .normal)
                IGNodePlayer.shared.pauseMusic()
            }  else {
                sender.setTitle("", for: .normal)
                IGNodePlayer.shared.playMusic()
            }
        },
                          completion: nil)
        IGGlobal.isPaused = !IGGlobal.isPaused
        
        
        
        
        
    }
    @objc func didTapOnPlayPause() {
        if self.actionPlay != nil {
            if  !(IGGlobal.isPaused){
                self.stopTimer()
                
            }  else {
                self.resumeTimer()
            }
            
            IGGlobal.isPaused = !IGGlobal.isPaused
        } else {
            if  !(IGGlobal.isPaused){
                self.stopTimer()
                
            }  else {
                self.resumeTimer()
            }
            
            
        }
    }
    func updateProgressView(currentTime : Float!,progressView: UIProgressView!){
        IGGlobal.isPaused = false
        
        currentMusicTime = currentTime
//        print("CURRENT TIME:",currentMusicTime!,(musicTotalTime))
        let percent = ((currentMusicTime * 100) / (IGGlobal.topBarSongTime)) / 100
        progressView.progress = percent
        progressView.setProgress(progressView.progress, animated: true)
        
        //        if musicTotalTime != 0 {
        //            (IGGlobal.isAlreadyOpen) = false
        //        } else {
        //            (IGGlobal.isAlreadyOpen) = true
        //
        //        }
        
        if IGGlobal.topBarSongTime != 0 {
            if currentMusicTime! >= (IGGlobal.topBarSongTime) {
                progressView.progress = 0.0
                self.removeMainViewFromSuperView(bgView: progressView.superview)
                
            }
            
        }
        
        
        //        self.progressView.progress = percent
    }
    
    
    func stopTimer() {
        if self.btnPlay != nil {
            //            self.btnPlay.setTitle("", for: .normal)
            IGNodePlayer.shared.pauseMusic()
        }
    }
    func resumeTimer() {
        
        if self.btnPlay != nil {
            //            self.btnPlay.setTitle("", for: .normal)
            IGNodePlayer.shared.playMusic()
        }
    }
    
    
    //MARK: - Create / Remove funcs
    ///TopMusicPlayer funcs
    ///MainView creation
    private func removeMainViewFromSuperView(bgView: UIView!) {
        SwiftEventBus.post(EventBusManager.hideTopMusicPlayer)
        self.isRunning = false
        currentMusicTime = 0
        
    if bgView != nil {
        bgView.removeFromSuperview()
        for subview in bgView.subviews {
            subview.removeFromSuperview()
        }
        IGGlobal.topBarSongTime = 0
        }
        let musicFile = MusicFile(songName: IGStringsManager.VoiceMessage.rawValue.localized , singerName: IGStringsManager.UnknownArtist.rawValue.localized, songTime: 0.0, currentTime: 0.0)
        
    }
    private func createMainView() -> UIView {
        let view = UIView()
        view.backgroundColor = ThemeManager.currentTheme.SliderTintColor
        //        view.backgroundColor = .red
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.tag = 404
        return view
    }
    ///Pause-Play Button
    private func createPausePlayButton(btn: UIButton!,view:UIView!)  {
        switch IGGlobal.songState {
        case .ended :
            btn.setTitle("", for: .normal)
            break
        case .playing :
            btn.setTitle("", for: .normal)
            break
        case .paused :
            btn.setTitle("", for: .normal)
            break
        default:
            break
        }
        let currentTheme = UserDefaults.standard.string(forKey: "CurrentTheme") ?? "IGAPClassic"
          let currentColorSetDark = UserDefaults.standard.string(forKey: "CurrentColorSetDark") ?? "IGAPBlue"
          let currentColorSetLight = UserDefaults.standard.string(forKey: "CurrentColorSetLight") ?? "IGAPBlue"

          if currentTheme == "IGAPDay" {
              
              if currentColorSetLight == "IGAPBlack" {
                  
                btn.setTitleColor(.white, for: .normal)

                  
              } else {
                  
                  btn.setTitleColor(.white, for: .normal)

              }
          } else {
              btn.setTitleColor(.white, for: .normal)

          }

        btn.titleLabel?.font = UIFont.iGapFonticon(ofSize: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 35).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 35).isActive = true
        btn.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true
        btn.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5).isActive = true
    }
    
    private func createCloseButton(btn: UIButton!,view:UIView!)  {
        btn.titleLabel?.font = UIFont.iGapFonticon(ofSize: 20)
        btn.setTitle("", for: .normal)

        let currentTheme = UserDefaults.standard.string(forKey: "CurrentTheme") ?? "IGAPClassic"
          let currentColorSetDark = UserDefaults.standard.string(forKey: "CurrentColorSetDark") ?? "IGAPBlue"
          let currentColorSetLight = UserDefaults.standard.string(forKey: "CurrentColorSetLight") ?? "IGAPBlue"

          if currentTheme == "IGAPDay" {
              
              if currentColorSetLight == "IGAPBlack" {
                  
                btn.setTitleColor(.white, for: .normal)

                  
              } else {
                  
                  btn.setTitleColor(.white, for: .normal)

              }
          } else {
              btn.setTitleColor(.white, for: .normal)

          }
        btn.titleLabel?.font = UIFont.iGapFonticon(ofSize: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 35).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 35).isActive = true
        btn.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true
        btn.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5).isActive = true
    }
    private func creatBorders(topBorder:UIView!,bottomBorder:UIView!,view: UIView!) {
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        topBorder.heightAnchor.constraint(equalToConstant:  0.5).isActive = true
        topBorder.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
        topBorder.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        topBorder.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        topBorder.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        topBorder.backgroundColor = ThemeManager.currentTheme.LabelGrayColor
        bottomBorder.backgroundColor = ThemeManager.currentTheme.LabelGrayColor
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBorder.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        bottomBorder.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
        bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        bottomBorder.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        bottomBorder.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        
    }
    private func createProgressView(pv:UIProgressView!,view: UIView!,bottomBorder:UIView!) {
        pv.progress = 0.0
        let currentTheme = UserDefaults.standard.string(forKey: "CurrentTheme") ?? "IGAPClassic"
          let currentColorSetDark = UserDefaults.standard.string(forKey: "CurrentColorSetDark") ?? "IGAPBlue"
          let currentColorSetLight = UserDefaults.standard.string(forKey: "CurrentColorSetLight") ?? "IGAPBlue"

          if currentTheme == "IGAPDay" {
              
              if currentColorSetLight == "IGAPBlack" {
                  
                pv.progressTintColor = .white

                  
              } else {
                  
                  pv.progressTintColor = ThemeManager.currentTheme.LabelColor

              }
          } else {
              pv.progressTintColor = ThemeManager.currentTheme.LabelColor

          }
        pv.progressViewStyle = .bar
        
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.heightAnchor.constraint(equalToConstant: 1).isActive = true
        pv.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor, constant: -1).isActive = true
        pv.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        pv.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        
    }
    private func createLabelsInPlayer(songName: UILabel!,singerName: UILabel!,view:UIView!) {
        songName.numberOfLines = 1
        songName.tag = 707
        songName.textAlignment = .center
        songName.font = UIFont.igFont(ofSize: 10 , weight: .bold)
        let currentTheme = UserDefaults.standard.string(forKey: "CurrentTheme") ?? "IGAPClassic"
        let currentColorSetDark = UserDefaults.standard.string(forKey: "CurrentColorSetDark") ?? "IGAPBlue"
        let currentColorSetLight = UserDefaults.standard.string(forKey: "CurrentColorSetLight") ?? "IGAPBlue"

        if currentTheme == "IGAPDay" {
            
            if currentColorSetLight == "IGAPBlack" {
                
                songName.textColor = .white

                
            } else {
                
                songName.textColor = .white

            }
        } else {
            songName.textColor = .white

        }


        songName.translatesAutoresizingMaskIntoConstraints = false
        songName.topAnchor.constraint(equalTo: view.topAnchor, constant: 5).isActive = true
        songName.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 45).isActive = true
        songName.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -45).isActive = true
        
        singerName.numberOfLines = 1
        singerName.tag = 708
        singerName.textAlignment = .center
        singerName.font = UIFont.igFont(ofSize: 10,weight : .light)
        if currentTheme == "IGAPDay" {
            
            if currentColorSetLight == "IGAPBlack" {
                
                singerName.textColor = .white

                
            } else {
                
                singerName.textColor = .white

            }
        } else {
            singerName.textColor = .white

        }
        singerName.translatesAutoresizingMaskIntoConstraints = false
        singerName.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5).isActive = true
        singerName.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 45).isActive = true
        singerName.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -45).isActive = true
        
    }
    
    
    
}

