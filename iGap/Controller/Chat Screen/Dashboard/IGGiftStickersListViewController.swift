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

class IGGiftStickersListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var tabbarHeight: CGFloat?
    var giftCardType: GiftStickerListType = .new
    var giftCardList: [IGStructGiftCardListData] = []
    var giftStickerInfo: SMCheckGiftSticker!
    var giftStickerAlertView: SMGiftStickerAlertView!
    var dismissBtn: UIButton!
    let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        initNavigationBar()
        manageShowActivties(isFirst: true)
        fetchGiftCards()
    }
    
    func initNavigationBar(){
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(title: IGStringsManager.GiftCardReport.rawValue.localized, width: 200)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }
    
    private func manageShowActivties(isFirst: Bool = false){
        if isFirst {
            self.tableView!.setEmptyMessage(IGStringsManager.WaitDataFetch.rawValue.localized)
        } else if giftCardList.count == 0 {
            self.tableView!.setEmptyMessage(IGStringsManager.GlobalNoHistory.rawValue.localized)
        } else {
            self.tableView!.restore()
        }
    }
    
    private func fetchGiftCards(){
        IGApiSticker.shared.giftStickerCardsList(status: giftCardType) { [weak self] giftCardList in
            for giftCard in giftCardList.data {
                self?.giftCardList.append(giftCard)
            }
            self?.manageShowActivties()
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    private func getCardStatus(stickerId: String, date: String){
        IGGlobal.prgShow()
        IGApiSticker.shared.getGiftCardGetStatus(stickerId: stickerId, completion: { [weak self] giftCardStatus in
            IGGlobal.prgHide()
            self?.showCardInfo(stickerInfo: giftCardStatus, date: date)
        }, error: {
            IGGlobal.prgHide()
        })
    }
    
    private func showCardInfo(stickerInfo: IGStructGiftCardStatus, date: String){
        self.dismissBtn = UIButton()
        self.dismissBtn.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        self.view.insertSubview(self.dismissBtn, at: 2)
        self.dismissBtn.addTarget(self, action: #selector(self.didtapOutSide), for: .touchUpInside)
        
        self.dismissBtn?.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.top)
            make.bottom.equalTo(self.view.snp.bottom)
            make.right.equalTo(self.view.snp.right)
            make.left.equalTo(self.view.snp.left)
        }
        
        self.giftStickerInfo = SMCheckGiftSticker.loadFromNib()
        self.giftStickerInfo.confirmBtn.addTarget(self, action: #selector(self.confirmTapped), for: .touchUpInside)
        self.giftStickerInfo.setInfo(giftSticker: stickerInfo, date: date)
        self.giftStickerInfo.frame = CGRect(x: 0, y: self.view.frame.height , width: self.view.frame.width, height: self.giftStickerInfo.frame.height)
        self.giftStickerInfo.infoLblOne.text = IGStringsManager.GiftCard.rawValue.localized
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(IGMessageViewController.handleGesture(gesture:)))
        swipeDown.direction = .down
        
        self.giftStickerInfo.addGestureRecognizer(swipeDown)
        self.view.addSubview(self.giftStickerInfo)
        
        UIView.animate(withDuration: 0.3) {
            self.giftStickerInfo.frame = CGRect(x: 0, y: self.view.frame.height - self.giftStickerInfo.frame.height - 5 -  self.bottomPadding!, width: self.view.frame.width, height: self.giftStickerInfo.frame.height)
        }
    }
    
    private func showActiveOrForward(){
        self.giftStickerAlertView = SMGiftStickerAlertView.loadFromNib()
        self.giftStickerAlertView.btnOne.addTarget(self, action: #selector(self.confirmTapped), for: .touchUpInside)
        self.giftStickerAlertView.btnTwo.addTarget(self, action: #selector(self.sendToAnother), for: .touchUpInside)
        self.giftStickerAlertView.frame = CGRect(x: 0, y: self.view.frame.height , width: self.view.frame.width, height: self.giftStickerAlertView.frame.height)
        manageButtonsView(buttons: [giftStickerAlertView.btnOne, giftStickerAlertView.btnTwo])
        giftStickerAlertView.btnOne.setTitle(IGStringsManager.Activation.rawValue.localized, for: UIControl.State.normal)
        giftStickerAlertView.btnTwo.setTitle(IGStringsManager.GiftStickerSendToOther.rawValue.localized, for: UIControl.State.normal)
        giftStickerAlertView.infoLblOne.text = IGStringsManager.ActivateOrSendAsMessage.rawValue.localized
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(IGMessageViewController.handleGesture(gesture:)))
        swipeDown.direction = .down
        
        self.giftStickerAlertView.addGestureRecognizer(swipeDown)
        self.view.addSubview(self.giftStickerAlertView)
        
        let yPosition = self.view.frame.height - self.giftStickerAlertView.frame.height - (self.bottomPadding! + tabbarHeight!)
        UIView.animate(withDuration: 0.3) {
            self.giftStickerAlertView.frame = CGRect(x: 0, y: yPosition, width: self.view.frame.width, height: self.giftStickerAlertView.frame.height)
        }
    }
    
    private func manageButtonsView(buttons: [UIButton]){
        for button in buttons {
            button.layer.cornerRadius = button.bounds.height / 2
            button.layer.borderColor = ThemeManager.currentTheme.LabelColor.cgColor
            button.layer.borderWidth = 1.0
        }
    }
    
    @objc func didtapOutSide(keepBackground: Bool = false) {
        UIView.animate(withDuration: 0.3, animations: {
            self.giftStickerInfo?.frame.origin.y = self.view.frame.height
            self.giftStickerAlertView?.frame.origin.y = self.view.frame.height
        }) { (true) in }

        let hideInfo = giftStickerInfo != nil
        let hideAlertView = giftStickerAlertView != nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if hideInfo {
                self.giftStickerInfo?.removeFromSuperview()
                self.giftStickerInfo = nil
            }
            
            if hideAlertView {
                self.giftStickerAlertView?.removeFromSuperview()
                self.giftStickerAlertView = nil
            }
            
            if !keepBackground {
                self.dismissBtn?.removeFromSuperview()
                self.dismissBtn = nil
            }
        }
    }
    
    @objc func handleGesture(gesture: UITapGestureRecognizer) {
        self.didtapOutSide(keepBackground: false)
    }
    
    @objc func confirmTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if giftStickerInfo != nil {
            didtapOutSide(keepBackground: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.showActiveOrForward()
            }
        } else if giftStickerAlertView != nil {
            didtapOutSide(keepBackground : false)
            print("SSS || confirmTapped")
        }
    }
    
    @objc func sendToAnother(_ gestureRecognizer: UITapGestureRecognizer) {
        print("SSS || sendToAnother")
    }
    
    // MARK:- TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return giftCardList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GiftCardListCell", for: indexPath) as! IGGiftStickerListCell
        cell.setInfo(giftCard: giftCardList[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let giftSticker = giftCardList[indexPath.row]
        getCardStatus(stickerId: giftSticker.id, date: giftSticker.createdAt)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
 }
