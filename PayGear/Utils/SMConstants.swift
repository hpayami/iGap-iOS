//
//  SMConstants.swift
//  PayGear
//
//  Created by a on 4/8/18.
//  Copyright © 2018 Samsoon. All rights reserved.
//

import UIKit
import maincore

struct SMConstants {
	
	static let notificationMerchant = "merchant.info.updated"
	
	
	static let version : String	= Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! String
	static let build : String 	= Bundle.main.infoDictionary!["CFBundleVersion"]! as! String
	
	static func sourceYear() -> Int {
		
		if SMLangUtil.lang == SMLangUtil.SMLanguage.English.rawValue {
			return 1900
		}
		return  1270
	}
}

struct SMLog {
	
	static func SMPrint<T>(_ message:T, function: String = #function) {
		#if DEBUG
		if let text = message as? String {
			print("SMPrint:\(function): \(text)")
		}
		#endif
	}
}
@objcMembers
class SMColor: NSObject {
        
    static let PrimaryColor                 = #colorLiteral(red: 0.1176470588, green: 0.5882352941, blue: 1, alpha: 1)
    static let InactiveField                = #colorLiteral(red: 0.5921568627, green: 0.5921568627, blue: 0.5921568627, alpha: 1)
    static let TitleTextColor               = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static let SignupTitleTextColor         = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    static let HintTextColor                = #colorLiteral(red: 0.1294117647, green: 0.5882352941, blue: 0.9529411765, alpha: 1)
    static let HintTranspatentTextColor     = #colorLiteral(red: 0.1294117647, green: 0.5882352941, blue: 0.9529411765, alpha: 0.4)
    static let Silver                       = #colorLiteral(red: 0.6980392157, green: 0.7450980392, blue: 0.768627451, alpha: 1)
    static let lightBlue                    = #colorLiteral(red: 0.8901960784, green: 0.9490196078, blue: 0.9921568627, alpha: 1)
}

struct SMDirection {
	
	public enum SMPageDirection : String {
		
		case RTL = "RightToLeft"
		case LTR = "LeftToRight"
	}
	
	static func PageAffineTransform() -> CGAffineTransform {
		return (SMLangUtil.lang == SMLangUtil.SMLanguage.English.rawValue) ? CGAffineTransform(scaleX: -1,y: 1) : CGAffineTransform(scaleX: 1,y: 1)
	}
	
	static func TextAlignment() -> NSTextAlignment {
		return (SMLangUtil.lang == SMLangUtil.SMLanguage.English.rawValue) ? .left : .right
	}
}

public enum SMPages:String {
    case IntroPage              = "intro@IntroPage"
    case IntroContentPage       = "introContentPage@IntroPage"
    case Splash                 = "splash@Splash"
    case Main                   = "main@MainTabBar"
    case Packet                 = "packet@Packet"
    case QR                     = "qr@QR"
    case AddCard                = "addcard@AddCard"
    case ChooseCard             = "choosecard@Packet"
    case PayCard                = "paycard@Packet"
    case PayAmount              = "payamount@Packet"
    case SignupPhonePage        = "signup@Signup"
    case ConfirmPhonePage       = "confirmPhone@Signup"
    case SetPasswordPage        = "setPassword@Signup"
    case RefferalPage           = "refferal@Signup"
    case LoginPage              = "login@Signup"
    case ProfilePage            = "profile@Profile"
    case MyQR                   = "myqr@QR"
    case WithDraw               = "withdraw@WithDraw"
    case Fast                   = "fastwithdraw@WithDraw"
    case TextFieldAlert         = "textalert@Alerts"
    case ConfirmAlert           = "confirmalert@Alerts"
    case UpdateAlert            = "updatealert@Alerts"
    case NormalAlert            = "normalalert@Alerts"
    case SavedCardsAlert        = "savedcards@Alerts"
    case HistoryTable           = "historytable@History"
    case HistoryDetail          = "historydetail@History"
	case ChooseLanguage		    = "language@Setting"
	case Merchant               = "merchant@Packet"
    case Service                = "service@Service"
	case Message 				= "message@Message"
}

struct SMFonts {
    
    static func IranYekanBold(_ size:Float) -> UIFont {
        return UIFont(name: "IRANYekanMobile-Bold", size: CGFloat(size))!
    }
    static func IranYekanLight(_ size:Float) -> UIFont {
        return UIFont(name: "IRANYekanMobile-Light", size: CGFloat(size))!
    }
    static func IranYekanRegular(_ size:Float) -> UIFont {
        return UIFont(name: "IRANYekanMobile", size: CGFloat(size))!
    }
    
}

@objcMembers
class SMQRCode:NSObject{
    
    static let URL                 = "https://paygear.ir/dl?jj="
    
    public enum SMAccountType:String {
        case User                = "8"
        case Merchant            = "9"
    }

}
    
struct SMMessage {
    
    static func showWithMessage(_ message: String) {
        
        let dialog = MC_message_dialog(title: MCLocalization.string(forKey: "GLOBAL_MESSAGE"), message: message, delegate: UIApplication.shared.delegate?.window??.rootViewController ?? UIViewController())
        let okBtn = MC_ActionDialog.action(withTitle: MCLocalization.string(forKey: "GLOBAL_OK"), style: MCMessageDialogActionButton.blue, handler: nil)
            dialog.addAction(okBtn)
        dialog.show()
    }
}

    struct SMImage {
        static func saveImage(image: UIImage, withName name: String) {
		
		let imageData = NSData(data: image.pngData()!)
		let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
														FileManager.SearchPathDomainMask.userDomainMask, true)
		let docs = paths[0] as NSString
		let name = name
		let fullPath = docs.appendingPathComponent(name)
		_ = imageData.write(toFile: fullPath, atomically: true)
	}
	
	static func getImage(imageName: String) -> UIImage? {
		
		var savedImage: UIImage?
		
		if let imagePath = SMImage.getFilePath(fileName: imageName) {
			savedImage = UIImage(contentsOfFile: imagePath)
		}
		else {
			savedImage = nil
		}
        
		return savedImage
	}
	
	static func getFilePath(fileName: String) -> String? {
		
		let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
		let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
		var filePath: String?
		let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
		if paths.count > 0 {
			let dirPath = paths[0] as NSString
			filePath = dirPath.appendingPathComponent(fileName)
		}
		else {
			filePath = nil
		}
		
		return filePath
	}
}
