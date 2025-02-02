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
import SnapKit
import SwiftEventBus

@available(iOS 10.0, *)
class IGStickerSectionHeader: UICollectionReusableView {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var stickerAddRemove: UILabel!
    
    var txtStickerTitle: UILabel!
    var txtStickerCount: UILabel!
    var sectionIndex: Int!
    var stickerTab: StickerTab!
    var realmSticker: IGRealmSticker!
    let ANIMATE_TIME = 0.2
    var stickerPageType: StickerPageType!
    
    func configure(sticker: IGRealmSticker) {
        stickerPageType = StickerPageType.MAIN
        makeStickerTitle(isAddStickerPage: false)
        stickerAddRemove.isHidden = true
        txtStickerTitle.text = sticker.name
    }
    
    func configurePreview(sticker: StickerTab, sectionIndex: Int, isGift: Bool) {
        self.stickerPageType = StickerPageType.PREVIEW
        self.stickerTab = sticker
        self.sectionIndex = sectionIndex
        
        var countName: String!
        if isGift {
            countName = IGStringsManager.GiftCard.rawValue.localized
            stickerAddRemove.isHidden = true
        } else {
            countName = IGStringsManager.Sticker.rawValue.localized
            let onStickerClick = UITapGestureRecognizer(target: self, action: #selector(self.didTapOnAddOrRemove(_:)))
            self.stickerAddRemove.addGestureRecognizer(onStickerClick)
            self.stickerAddRemove.isUserInteractionEnabled = true
            makeStickerAddButton()
        }
        
        makeStickerTitle(isAddStickerPage: true)
        makeStickerCount()
        
        txtStickerTitle.text = sticker.name
        txtStickerCount.text = String(describing: sticker.stickers.count).inLocalizedLanguage() + " " + countName
    }
    
    func configureListPage(sticker: StickerTab, sectionIndex: Int, isGift: Bool) {
        self.stickerPageType = StickerPageType.CATEGORY
        self.stickerTab = sticker
        self.sectionIndex = sectionIndex
        
        var countName: String!
        if isGift {
            countName = IGStringsManager.GiftCard.rawValue.localized
            stickerAddRemove.isHidden = true
        } else {
            countName = IGStringsManager.Sticker.rawValue.localized
            let onStickerClick = UITapGestureRecognizer(target: self, action: #selector(self.didTapOnAddOrRemove(_:)))
            self.stickerAddRemove.addGestureRecognizer(onStickerClick)
            self.stickerAddRemove.isUserInteractionEnabled = true
            makeStickerAddButton()
        }
        
        makeStickerTitle(isAddStickerPage: true)
        makeStickerCount()
        
        txtStickerTitle.text = sticker.name
        txtStickerCount.text = String(describing: sticker.stickers.count).inLocalizedLanguage() + " " + countName
    }
    
    @objc func didTapOnAddOrRemove(_ gestureRecognizer: UITapGestureRecognizer) {
        UIView.transition(with: self.stickerAddRemove, duration: self.ANIMATE_TIME, options: .transitionFlipFromBottom, animations: {
            self.stickerAddRemove.isHidden = true
            self.changeRemoveAdd()
        }, completion: nil)
    }
    
    private func changeRemoveAdd(){
        if IGRealmSticker.isMySticker(id: self.stickerTab.id) {
            
            IGGlobal.prgShow(self)
            IGApiSticker.shared.removeSticker(groupId: self.stickerTab.id) { (success) in
                if success {
                    IGFactory.shared.removeSticker(groupId: self.stickerTab.id)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if success {
                        SwiftEventBus.postToMainThread(EventBusManager.stickerAdd, sender: self.sectionIndex)
                    }
                    
                    UIView.transition(with: self.stickerAddRemove, duration: self.ANIMATE_TIME, options: .transitionFlipFromTop, animations: {
                        self.stickerAddRemove.isHidden = false
                    }, completion: nil)
                    
                    IGGlobal.prgHide()
                }
            }
            
        } else {
            
            IGGlobal.prgShow(self)
            IGApiSticker.shared.addSticker(groupId: self.stickerTab.id) { (success) in
                if success {
                    IGFactory.shared.addSticker(stickers: [self.stickerTab])
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if success {
                        SwiftEventBus.postToMainThread(EventBusManager.stickerAdd, sender: self.sectionIndex)
                    }
                    
                    UIView.transition(with: self.stickerAddRemove, duration: self.ANIMATE_TIME, options: .transitionFlipFromTop, animations: {
                        self.stickerAddRemove.isHidden = false
                    }, completion: nil)
                    
                    IGGlobal.prgHide()
                }
            }
            
        }
    }
    
    /******************************************/
    /*************** View Maker ***************/
    
    private func makeStickerTitle(isAddStickerPage: Bool){
        if txtStickerTitle == nil {
            txtStickerTitle = UILabel()
            mainView.addSubview(txtStickerTitle)
            
            if isAddStickerPage {
                txtStickerTitle.font = UIFont.igFont(ofSize: 15, weight: .bold)
                txtStickerTitle.textColor = ThemeManager.currentTheme.LabelGrayColor
                
                txtStickerTitle.snp.makeConstraints { (make) in
                    make.left.equalTo(mainView.snp.left).offset(10)
                    make.centerY.equalTo(mainView.snp.centerY).offset(-12)
                    make.width.greaterThanOrEqualTo(50)
                    make.height.equalTo(30)
                }
            } else {
                txtStickerTitle.font = UIFont.igFont(ofSize: 13, weight: .medium)
                txtStickerTitle.textColor = UIColor.iGapDarkGreenColor()
                
                txtStickerTitle.snp.makeConstraints { (make) in
                    make.left.equalTo(mainView.snp.left).offset(10)
                    make.centerY.equalTo(mainView.snp.centerY).offset(10)
                    make.width.greaterThanOrEqualTo(50)
                    make.height.equalTo(30)
                }
            }
        }
    }
    
    private func makeStickerCount(){
        if txtStickerCount == nil {
            txtStickerCount = UILabel()
            txtStickerCount.font = UIFont.igFont(ofSize: 12, weight: .medium)
            txtStickerCount.textColor = UIColor.iGapDarkGreenColor()

            mainView.addSubview(txtStickerCount)
            
            txtStickerCount.snp.makeConstraints { (make) in
                make.left.equalTo(mainView.snp.left).offset(10)
                make.centerY.equalTo(mainView.snp.centerY).offset(12)
                make.width.greaterThanOrEqualTo(50)
                make.height.equalTo(20)
            }
        }
    }
    
    private func makeStickerAddButton(){
        
        stickerAddRemove.layer.borderWidth = 1
        stickerAddRemove.layer.cornerRadius = 8
        stickerAddRemove.layer.masksToBounds = true
        
        if IGRealmSticker.isMySticker(id: self.stickerTab.id) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.stickerAddRemove.layer.borderColor = UIColor.swipeRed().cgColor
                self.stickerAddRemove.textColor = UIColor.swipeRed()
                self.stickerAddRemove.text = IGStringsManager.Delete.rawValue.localized
                self.stickerAddRemove.font = UIFont.igFont(ofSize: 17)

            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.stickerAddRemove.layer.borderColor = UIColor.systemBlue.cgColor
                self.stickerAddRemove.textColor = UIColor.systemBlue
                self.stickerAddRemove.text = IGStringsManager.Add.rawValue.localized
                self.stickerAddRemove.font = UIFont.igFont(ofSize: 17)
            }
        }
    }
}
