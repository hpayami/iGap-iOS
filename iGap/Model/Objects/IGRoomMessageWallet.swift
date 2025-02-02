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

class IGRoomMessageWallet: Object {
    @objc dynamic var id:                String?
    @objc dynamic var type:              Int      = IGPRoomMessageWallet.IGPType.moneyTransfer.rawValue
    @objc dynamic var moneyTrasfer:      IGRoomMessageMoneyTransfer?
    @objc dynamic var payment:           IGRoomMessageMoneyTransfer?
    @objc dynamic var cardToCard:        IGRoomMessageCardToCard?
    @objc dynamic var bill:              IGRoomMessageBill?
    @objc dynamic var topup:             IGRoomMessageTopup?
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    convenience init(igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) {
        self.init()
        self.id = message.primaryKeyId
        self.type = igpRoomMessageWallet.igpType.rawValue
        
        let realm = try! Realm()
        if igpRoomMessageWallet.igpType == .moneyTransfer {
            self.moneyTrasfer = IGRoomMessageMoneyTransfer.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        } else if igpRoomMessageWallet.igpType == .payment {
            self.payment = IGRoomMessageMoneyTransfer.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        } else if igpRoomMessageWallet.igpType == .cardToCard {
            self.cardToCard = IGRoomMessageCardToCard.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        }
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) -> IGRoomMessageWallet {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        var wallet: IGRoomMessageWallet! = realm.objects(IGRoomMessageWallet.self).filter(predicate).first

        if wallet == nil {
            wallet = IGRoomMessageWallet()
            wallet.id = message.primaryKeyId
        }

        wallet.type = igpRoomMessageWallet.igpType.rawValue
        if igpRoomMessageWallet.igpType == .moneyTransfer {
            wallet.moneyTrasfer = IGRoomMessageMoneyTransfer.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        } else if igpRoomMessageWallet.igpType == .payment {
            wallet.payment = IGRoomMessageMoneyTransfer.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        } else if igpRoomMessageWallet.igpType == .cardToCard {
            wallet.cardToCard = IGRoomMessageCardToCard.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        } else if igpRoomMessageWallet.igpType == .bill {
            wallet.bill = IGRoomMessageBill.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        } else if igpRoomMessageWallet.igpType == .topup {
            wallet.topup = IGRoomMessageTopup.putOrUpdate(realm: realm, igpRoomMessageWallet: igpRoomMessageWallet, for: message)
        }
        
        return wallet
    }
    
    func detach() -> IGRoomMessageWallet {
        let detachedRoomMessageWallet = IGRoomMessageWallet(value: self)
        if self.moneyTrasfer != nil {
            detachedRoomMessageWallet.moneyTrasfer = self.moneyTrasfer?.detach()
        }
        if self.payment != nil {
            detachedRoomMessageWallet.payment = self.moneyTrasfer?.detach()
        }
        if self.cardToCard != nil {
            detachedRoomMessageWallet.cardToCard = self.cardToCard?.detach()
        }
        if self.topup != nil {
            detachedRoomMessageWallet.topup = self.topup?.detach()
        }
        if self.bill != nil {
            detachedRoomMessageWallet.bill = self.bill?.detach()
        }

        return detachedRoomMessageWallet
    }
}


class IGRoomMessageMoneyTransfer: Object {
    @objc dynamic var id:                String?
    @objc dynamic var fromUserId:        Int64    = 0
    @objc dynamic var toUserId:          Int64    = 0
    @objc dynamic var amount:            Int64    = 0
    @objc dynamic var traceNumber:       Int64    = 0
    @objc dynamic var invoiceNumber:     Int64    = 0
    @objc dynamic var payTime:           Int32    = 0
    @objc dynamic var cardNumber:        String?
    @objc dynamic var rrn:               Int64    = 0
    @objc dynamic var desc:              String?
    @objc dynamic var walletDescription: String?
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) -> IGRoomMessageMoneyTransfer {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        var moneyTransfer: IGRoomMessageMoneyTransfer! = realm.objects(IGRoomMessageMoneyTransfer.self).filter(predicate).first
        
        if moneyTransfer == nil {
            moneyTransfer = IGRoomMessageMoneyTransfer()
            moneyTransfer.id = message.primaryKeyId
        }
        
        moneyTransfer.fromUserId = igpRoomMessageWallet.igpMoneyTransfer.igpFromUserID
        moneyTransfer.toUserId = igpRoomMessageWallet.igpMoneyTransfer.igpToUserID
        moneyTransfer.amount = igpRoomMessageWallet.igpMoneyTransfer.igpAmount
        moneyTransfer.traceNumber = igpRoomMessageWallet.igpMoneyTransfer.igpTraceNumber
        moneyTransfer.invoiceNumber = igpRoomMessageWallet.igpMoneyTransfer.igpInvoiceNumber
        moneyTransfer.payTime = igpRoomMessageWallet.igpMoneyTransfer.igpPayTime
        moneyTransfer.walletDescription = igpRoomMessageWallet.igpMoneyTransfer.igpDescription
        moneyTransfer.cardNumber = igpRoomMessageWallet.igpMoneyTransfer.igpCardNumber
        moneyTransfer.rrn = igpRoomMessageWallet.igpMoneyTransfer.igpRrn
        moneyTransfer.desc = igpRoomMessageWallet.igpMoneyTransfer.igpDescription
        return moneyTransfer
    }
    
    func detach() -> IGRoomMessageMoneyTransfer {
        let detachedRoomMessageMoneyTransfer = IGRoomMessageMoneyTransfer(value: self)
        return detachedRoomMessageMoneyTransfer
    }
}

class IGRoomMessageCardToCard: Object {
    @objc dynamic var id:                String?
    @objc dynamic var fromUserId:        Int64    = 0
    @objc dynamic var toUserId:          Int64    = 0
    @objc dynamic var orderId:           Int64    = 0
    @objc dynamic var token:             String?
    @objc dynamic var amount:            Int64    = 0
    @objc dynamic var sourceCardNumber:  String?
    @objc dynamic var destCardNumber:    String?
    @objc dynamic var requestTime:       Int32    = 0
    @objc dynamic var rrn:               String?
    @objc dynamic var traceNumber:       String?
    @objc dynamic var bankName:          String?
    @objc dynamic var destBankName:      String?
    @objc dynamic var cardOwnerName:     String?
    @objc dynamic var status:            Bool     = false
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) -> IGRoomMessageCardToCard {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        var cardToCard: IGRoomMessageCardToCard! = realm.objects(IGRoomMessageCardToCard.self).filter(predicate).first
        
        if cardToCard == nil {
            cardToCard = IGRoomMessageCardToCard()
            cardToCard.id = message.primaryKeyId
        }
        
        cardToCard.fromUserId = igpRoomMessageWallet.igpCardToCard.igpFromUserID
        cardToCard.toUserId = igpRoomMessageWallet.igpCardToCard.igpToUserID
        cardToCard.orderId = igpRoomMessageWallet.igpCardToCard.igpOrderID
        cardToCard.token = igpRoomMessageWallet.igpCardToCard.igpToken
        cardToCard.amount = igpRoomMessageWallet.igpCardToCard.igpAmount
        cardToCard.sourceCardNumber = igpRoomMessageWallet.igpCardToCard.igpSourceCardNumber
        cardToCard.destCardNumber = igpRoomMessageWallet.igpCardToCard.igpDestCardNumber
        cardToCard.requestTime = igpRoomMessageWallet.igpCardToCard.igpRequestTime
        cardToCard.rrn = igpRoomMessageWallet.igpCardToCard.igpRrn
        cardToCard.traceNumber = igpRoomMessageWallet.igpCardToCard.igpTraceNumber
        cardToCard.bankName = igpRoomMessageWallet.igpCardToCard.igpBankName
        cardToCard.destBankName = igpRoomMessageWallet.igpCardToCard.igpDestBankName
        cardToCard.cardOwnerName = igpRoomMessageWallet.igpCardToCard.igpCardOwnerName
        cardToCard.status = igpRoomMessageWallet.igpCardToCard.igpStatus
        return cardToCard
    }
    
    func detach() -> IGRoomMessageCardToCard {
        let detachedRoomMessageCardToCard = IGRoomMessageCardToCard(value: self)
        return detachedRoomMessageCardToCard
    }
}


class IGRoomMessageBill: Object {
    @objc dynamic var id:                String?
    @objc dynamic var fromUserId:        Int64    = 0
    @objc dynamic var orderId:           Int64    = 0
    @objc dynamic var myToken:           String?
    @objc dynamic var token:             Int64    = 0
    @objc dynamic var amount:            Int64    = 0
    @objc dynamic var payId:             String?
    @objc dynamic var billId:            String?
    @objc dynamic var billType:          String?
    @objc dynamic var cardNumber:        String?
    @objc dynamic var merchantNumber:    String?
    @objc dynamic var terminalNo:        Int64    = 0
    @objc dynamic var rrn:               Int64    = 0
    @objc dynamic var traceNumber:       Int64    = 0
    @objc dynamic var requestTime:       Int32    = 0
    @objc dynamic var status:            Bool     = false
    @objc dynamic var statusDescription: String?
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) -> IGRoomMessageBill {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        var bill: IGRoomMessageBill! = realm.objects(IGRoomMessageBill.self).filter(predicate).first
        
        if bill == nil {
            bill = IGRoomMessageBill()
            bill.id = message.primaryKeyId
        }
        
        bill.fromUserId = igpRoomMessageWallet.igpBill.igpFromUserID
        bill.orderId = igpRoomMessageWallet.igpBill.igpOrderID
        bill.myToken = igpRoomMessageWallet.igpBill.igpMyToken
        bill.token = igpRoomMessageWallet.igpBill.igpToken
        bill.amount = igpRoomMessageWallet.igpBill.igpAmount
        bill.payId = igpRoomMessageWallet.igpBill.igpPayID
        bill.billId = igpRoomMessageWallet.igpBill.igpBillID
        bill.billType = igpRoomMessageWallet.igpBill.igpBillType
        bill.cardNumber = igpRoomMessageWallet.igpBill.igpCardNumber
        bill.merchantNumber = igpRoomMessageWallet.igpBill.igpMerchantName
        bill.terminalNo = igpRoomMessageWallet.igpBill.igpTerminalNo
        bill.rrn = igpRoomMessageWallet.igpBill.igpRrn
        bill.traceNumber = igpRoomMessageWallet.igpBill.igpTraceNumber
        bill.requestTime = igpRoomMessageWallet.igpBill.igpRequestTime
        bill.status = igpRoomMessageWallet.igpBill.igpStatus
        bill.statusDescription = igpRoomMessageWallet.igpBill.igpStatusDescription
        return bill
    }
    
    func detach() -> IGRoomMessageBill {
        let detachedRoomMessageBill = IGRoomMessageBill(value: self)
        return detachedRoomMessageBill
    }
}


class IGRoomMessageTopup: Object {
    
    @objc dynamic var id:                    String?
    @objc dynamic var topupType:             IGPRoomMessageWallet.IGPTopup.IGPType.RawValue = IGPRoomMessageWallet.IGPTopup.IGPType.mci.rawValue
    @objc dynamic var fromUserId:            Int64    = 0
    @objc dynamic var orderId:               Int64    = 0
    @objc dynamic var myToken:               String?
    @objc dynamic var token:                 Int64    = 0
    @objc dynamic var amount:                Int64    = 0
    @objc dynamic var requesterMobileNumber: String?
    @objc dynamic var chargeMobileNumber:    String?
    @objc dynamic var cardNumber:            String?
    @objc dynamic var merchantNumber:        String?
    @objc dynamic var terminalNo:            Int64    = 0
    @objc dynamic var rrn:                   Int64    = 0
    @objc dynamic var traceNumber:           Int64    = 0
    @objc dynamic var requestTime:           Int32    = 0
    @objc dynamic var status:                Bool     = false
    @objc dynamic var statusDescription:     String?
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) -> IGRoomMessageTopup {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        var topup: IGRoomMessageTopup! = realm.objects(IGRoomMessageTopup.self).filter(predicate).first
        
        if topup == nil {
            topup = IGRoomMessageTopup()
            topup.id = message.primaryKeyId
        }
        
        topup.topupType = igpRoomMessageWallet.igpTopup.igpTopupType.rawValue
        topup.fromUserId = igpRoomMessageWallet.igpTopup.igpFromUserID
        topup.orderId = igpRoomMessageWallet.igpTopup.igpOrderID
        topup.myToken = igpRoomMessageWallet.igpTopup.igpMyToken
        topup.token = igpRoomMessageWallet.igpTopup.igpToken
        topup.amount = igpRoomMessageWallet.igpTopup.igpAmount
        topup.requesterMobileNumber = igpRoomMessageWallet.igpTopup.igpRequesterMobileNumber
        topup.chargeMobileNumber = igpRoomMessageWallet.igpTopup.igpChargeMobileNumber
        topup.cardNumber = igpRoomMessageWallet.igpTopup.igpCardNumber
        topup.merchantNumber = igpRoomMessageWallet.igpTopup.igpMerchantName
        topup.terminalNo = igpRoomMessageWallet.igpTopup.igpTerminalNo
        topup.rrn = igpRoomMessageWallet.igpTopup.igpRrn
        topup.traceNumber = igpRoomMessageWallet.igpTopup.igpTraceNumber
        topup.requestTime = igpRoomMessageWallet.igpTopup.igpRequestTime
        topup.status = igpRoomMessageWallet.igpTopup.igpStatus
        topup.statusDescription = igpRoomMessageWallet.igpTopup.igpStatusDescription
        return topup
    }
    
    func detach() -> IGRoomMessageTopup {
        let detachedRoomMessageTopup = IGRoomMessageTopup(value: self)
        return detachedRoomMessageTopup
    }
}
