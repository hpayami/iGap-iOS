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

class IGInfoLocationRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate() -> IGRequestWrapper{
            let locationInfoRequestMessage = IGPInfoLocation()
            return IGRequestWrapper(message: locationInfoRequestMessage, actionID: 500)
        }
    }
    
    class Handler : IGRequest.Handler{
        class func interpret(response responseProtoMessage:IGPInfoLocationResponse ) -> IGCountryInfo {
            let country = IGCountryInfo()
            country.countryISO = responseProtoMessage.igpIsoCode
            country.countryCode = responseProtoMessage.igpCallingCode
            country.countryName = responseProtoMessage.igpName
            country.codePattern = responseProtoMessage.igpPattern
            country.codeRegex = responseProtoMessage.igpRegex
            country.codePatternMask = responseProtoMessage.igpPattern
            
            return country
            
        }
        override class func handlePush(responseProtoMessage: Message) {}
    }
}

//MARK: -
class IGInfoCountryRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(countryCode : String) -> IGRequestWrapper{
            var countryInfoRequestMessage = IGPInfoCountry()
            countryInfoRequestMessage.igpIsoCode = countryCode
            return IGRequestWrapper(message: countryInfoRequestMessage, actionID: 501)
        }
    }
    
    class Handler : IGRequest.Handler{
        override class func handlePush(responseProtoMessage: Message) {}
    }
}

//MARK: -
class IGInfoTimeRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate() -> IGRequestWrapper{
            let timeInfoRequestMessage = IGPInfoTime()
            return IGRequestWrapper(message: timeInfoRequestMessage, actionID: 502)
        }
    }
    
    class Handler : IGRequest.Handler{
        override class func handlePush(responseProtoMessage: Message) {}
    }
}

//MARK: -
class IGInfoPageRequest : IGRequest {
    class Generator : IGRequest.Generator{
        class func generate(pageID: String) -> IGRequestWrapper {
            var pageInfoRequestMessage = IGPInfoPage()
            pageInfoRequestMessage.igpID = pageID
            return IGRequestWrapper(message: pageInfoRequestMessage, actionID: 503)
        }
    }
    
    class Handler : IGRequest.Handler {
        class func interpret(response responseProtoMessage: IGPInfoPageResponse) -> String {
            return responseProtoMessage.igpBody
        }
        
        override class func handlePush(responseProtoMessage: Message) {}
    }
}


class IGInfoWallpaperRequest: IGRequest {
    class Generator: IGRequest.Generator{
        class func generate(fit: IGPInfoWallpaper.IGPFit, type: IGPInfoWallpaper.IGPType = .chatBackground) -> IGRequestWrapper {
            var wallpaper = IGPInfoWallpaper()
            wallpaper.igpFit = fit
            wallpaper.igpType = type
            return IGRequestWrapper(message: wallpaper, actionID: 504, identity: wallpaper)
        }
    }
    
    class Handler: IGRequest.Handler {
        class func interpret(response responseProtoMessage:IGPInfoWallpaperResponse , type: IGPInfoWallpaper.IGPType = .chatBackground) {
            IGFactory.shared.saveWallpaper(wallpapers: responseProtoMessage.igpWallpaper ,type: type)
        }
        
        override class func handlePush(responseProtoMessage: Message) {}
    }
}

class IGInfoUpdateResponse: IGRequest {
    class Generator: IGRequest.Generator {
        class func generate() -> IGRequestWrapper {
            var infoUpdate = IGPInfoUpdate()
            if let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                if let buildV = Int32(buildVersion) {
                    infoUpdate.igpAppBuildVersion = Int32(buildV)
                } else {
                   infoUpdate.igpAppBuildVersion = Int32(1)
                }
            } else {
                infoUpdate.igpAppBuildVersion = Int32(1)
            }
            
//            infoUpdate.igpAppBuildVersion = Int32(510)
            
            infoUpdate.igpAppID = 3
            return IGRequestWrapper(message: infoUpdate, actionID: 505, identity: infoUpdate)
        }
    }
    
    class Handler: IGRequest.Handler {
        class func interpret(response responseProtoMessage: IGPInfoUpdateResponse) -> String {
            return responseProtoMessage.igpBody
        }
        
        override class func handlePush(responseProtoMessage: Message) {}
    }
}

