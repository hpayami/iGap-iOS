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
import Alamofire
import SwiftyJSON
import Realm

class IGApiElectricityBill: IGApiBase {
    
    enum Endpoint {
        case addBill
        case editBill
        case deleteBill
        case getBills
        case queryBill
        case branchingInfo
        case getImageOfBill
        
        var url: String {
            var urlString = IGApiElectricityBill.electricityBillBaseUrl
            
            switch self {
            case .queryBill:
                urlString += "/api/get-branch-debit"
            case .addBill:
                urlString += "/api/add-bill"
            case .editBill:
                urlString += "/api/edit-bill"
            case .deleteBill:
                urlString += "/api/delete-bill"
            case .getBills:
                break
            case .branchingInfo:
                urlString += "/api/get-branch-info"
            case .getImageOfBill:
                urlString += "/api/get-last-bill"
                
            }
            
            return urlString
        }
    }
    
    static let shared = IGApiElectricityBill()
    private static let electricityBillBaseUrl = "https://api.igap.net/bill/v1.0"
    
    
    func queryBill(billNumber: String,phoneNumber: String, completion: @escaping ((_ success: Bool, _ response: IGStructInqueryBill?, _ errorMessage: String?) -> Void) ) {
        let parameters: Parameters = ["bill_identifier" : billNumber, "mobile_number" : phoneNumber]
        
        AF.request(Endpoint.queryBill.url, method: .post,parameters: parameters,headers: self.getHeader()).responseData { (response) in
            
            if self.needToRetryRequest(statusCode: response.response?.statusCode, completion: {
                self.queryBill(billNumber: billNumber, phoneNumber: phoneNumber, completion: completion)
            }) {
            } else {
                let json = try? JSON(data: response.data ?? Data())
                switch response.result {
                case .success(let value):
                    do {
                        let classData = try JSONDecoder().decode(IGStructInqueryBill.self, from: value)
                        completion(true, classData, nil)
                    } catch _ {
                        guard json != nil, let message = json!["message"].string else {
                            completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                            return
                        }
                        completion(false, nil, message)
                    }
                    
                case .failure(_):
                    guard json != nil, let message = json!["message"].string else {
                        completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                        return
                    }
                    completion(false, nil, message)
                }
            }
        }
    }
    
    
    func branchingInfo(billNumber: String,phoneNumber: String, completion: @escaping ((_ success: Bool, _ response: IGStructBranchingInfo?, _ errorMessage: String?) -> Void) ) {
        let parameters: Parameters = ["bill_identifier" : billNumber, "mobile_number" : phoneNumber]
        AF.request(Endpoint.branchingInfo.url, method: .post,parameters: parameters,headers: self.getHeader()).responseData { (response) in
            
            if self.needToRetryRequest(statusCode: response.response?.statusCode, completion: {
                self.branchingInfo(billNumber: billNumber, phoneNumber: phoneNumber, completion: completion)
            }) {
            } else {
                let json = try? JSON(data: response.data ?? Data())
                switch response.response?.statusCode {
                case 200:
                    
                    switch response.result {
                        
                    case .success(let value):
                        do {
                            let classData = try JSONDecoder().decode(IGStructBranchingInfo.self, from: value)
                            completion(true, classData, nil)
                        } catch _ {
                            guard json != nil, let message = json!["message"].string else {
                                completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                                return
                            }
                            completion(false, nil, message)
                        }
                        
                    case .failure(_):
                        guard json != nil, let message = json!["message"].string else {
                            completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                            return
                        }
                        completion(false, nil, message)
                    }
                    
                default :
                    guard json != nil, let message = json!["message"].string else {
                        completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                        return
                    }
                    completion(false, nil, message)
                }
            }
        }
    }
    
    ////////////////////////////GET IMAGE OF BILL////////////////////////////////
    func getImageOfBill(billNumber: String,phoneNumber: String, completion: @escaping ((_ success: Bool, _ response: IGStructBillImage?, _ errorMessage: String?) -> Void) ) {
        let parameters: Parameters = ["bill_identifier" : billNumber, "mobile_number" : phoneNumber]
        AF.request(Endpoint.getImageOfBill.url, method: .post,parameters: parameters,headers: self.getHeader()).responseData { (response) in
            
            if self.needToRetryRequest(statusCode: response.response?.statusCode, completion: {
                self.getImageOfBill(billNumber: billNumber, phoneNumber: phoneNumber, completion: completion)
            }) {
            } else {
                
                let json = try? JSON(data: response.data ?? Data())
                switch response.response?.statusCode {
                case 200:
                    
                    switch response.result {
                    case .success(let value):
                        do {
                            let classData = try JSONDecoder().decode(IGStructBillImage.self, from: value)
                            completion(true, classData, nil)
                        } catch _ {
                            guard json != nil, let message = json!["message"].string else {
                                completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                                return
                            }
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                            completion(false, nil, message)
                        }

                    case .failure(_):
                        guard json != nil, let message = json!["message"].string else {
                            completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                            return
                        }
                        IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                        completion(false, nil, message)
                    }
                    
                    break
                    
                default :
                    guard json != nil, let message = json!["message"].string else {
                        completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                        return
                    }
                    IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                    completion(false, nil, message)
                }
            }
        }
    }
    
    
    ////////////////////////////EDIT BILL INFO////////////////////////////////
    func editBill(billNumber: String,phoneNumber: String,nationalCode : String? = "",email: String? = "",billTitle : String? = "" ,viaSMS : Bool? = true,viaAP : Bool? = false,viaPRINT : Bool? = false,viaEmail : Bool? = false, completion: @escaping ((_ success: Bool, _ response: IGStructBillImage?, _ errorMessage: String?) -> Void) ) {
        let parameters: Parameters = ["bill_identifier" : billNumber, "mobile_number" : phoneNumber]
        
        AF.request(Endpoint.getImageOfBill.url, method: .post,parameters: parameters,headers: self.getHeader()).responseData { (response) in
            if self.needToRetryRequest(statusCode: response.response?.statusCode, completion: {
                self.editBill(billNumber: billNumber, phoneNumber: phoneNumber, completion: completion)
            }) {
            } else {
                let json = try? JSON(data: response.data ?? Data())
                
                switch response.response?.statusCode {
                case 200:
                    
                    switch response.result {
                        
                    case .success(let value):
                        do {
                            let classData = try JSONDecoder().decode(IGStructBillImage.self, from: value)
                            completion(true, classData, nil)
                        } catch _ {
                            guard json != nil, let message = json!["message"].string else {
                                completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                                return
                            }
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                            completion(false, nil, message)
                        }
                        
                    case .failure(_):
                        guard json != nil, let message = json!["message"].string else {
                            completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                            return
                        }
                        IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                        completion(false, nil, message)
                    }
                    
                default :
                    guard json != nil, let message = json!["message"].string else {
                        completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                        return
                    }
                    IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                    completion(false, nil, message)
                }
            }
        }
    }

    ////////////////////////////ADD TO MY BILL LIST////////////////////////////////
    func addBill(billNumber: String,phoneNumber: String,nationalCode : String? = "",email: String? = "",billTitle : String? = "" ,viaSMS : Bool? = true,viaAP : Bool? = false,viaPRINT : Bool? = false,viaEmail : Bool? = false, completion: @escaping ((_ success: Bool, _ response: IGStructBillImage?, _ errorMessage: String?) -> Void) ) {
        let parameters: Parameters = ["bill_identifier" : billNumber, "mobile_number" : phoneNumber]
        
        AF.request(Endpoint.getImageOfBill.url, method: .post,parameters: parameters,headers: self.getHeader()).responseData { (response) in
            
            if self.needToRetryRequest(statusCode: response.response?.statusCode, completion: {
                self.addBill(billNumber: billNumber, phoneNumber: phoneNumber, completion: completion)
            }) {
            } else {
                let json = try? JSON(data: response.data ?? Data())
                
                switch response.response?.statusCode {
                case 200:
                    
                    switch response.result {
                        
                    case .success(let value):
                        do {
                            let classData = try JSONDecoder().decode(IGStructBillImage.self, from: value)
                            completion(true, classData, nil)
                        } catch _ {
                            guard json != nil, let message = json!["message"].string else {
                                completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                                return
                            }
                            IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                            completion(false, nil, message)
                        }
                        
                    case .failure(_):
                        guard json != nil, let message = json!["message"].string else {
                            completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                            return
                        }
                        IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                        completion(false, nil, message)
                    }
                    
                default :
                    guard json != nil, let message = json!["message"].string else {
                        completion(false, nil, "UNSSUCCESS_OTP".localizedNew)
                        return
                    }
                    IGHelperAlert.shared.showCustomAlert(view: nil, alertType: .alert, title: "GLOBAL_WARNING".localizedNew, showIconView: true, showDoneButton: false, showCancelButton: true, message: message, cancelText: "GLOBAL_CLOSE".localizedNew)
                    completion(false, nil, message)
                }
            }
        }
    }
}
