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
import IGProtoBuff

typealias MessageCalculatedSize = (bubbleSize: CGSize, messageAttachmentHeight: CGFloat, additionalHeight: CGFloat)

class CellSizeCalculator: NSObject {
    
    private var cache : NSCache<NSString, AnyObject>
    private static let EXTRA_HEIGHT_RTL_OR_VOTE = 20
    public static let IMG_REPLY_DEFAULT_HEIGHT = 30
    internal static let RTL_OFFSET = -(EXTRA_HEIGHT_RTL_OR_VOTE - 7)
    
    static let sharedCalculator = CellSizeCalculator()
    
    private override init() {
        cache = NSCache()
        cache.countLimit = 200
        cache.name = "im.igap.cache.CellSizeCalculator"
    }
    
    class func messageBodyTextViewFont() -> UIFont {
        return UIFont.igFont(ofSize: 14.3)
    }
    
    private static func computeSizeFont() -> UIFont {
        return UIFont.igFont(ofSize: fontDefaultSize)
    }
    
    func clearBubbleSizeCache(){
        cache.removeAllObjects()
    }
    
    /** when "showAvatar" is true also should be show sender name */
    func mainBubbleCountainerSize(room: IGRoom, for message:IGRoomMessage, showAvatar: Bool = false) -> MessageCalculatedSize {
        
        if message.isInvalidated || room.isInvalidated {
            return (CGSize.zero, 0, 0)
        }
        
        let cacheKey = "\(String(describing: message.primaryKeyId))_\(message.messageVersion)" as NSString
        let cachedSize = cache.object(forKey: cacheKey)
        if cachedSize != nil {
            return cachedSize as! MessageCalculatedSize
        }

        var finalSize = CGSize.zero
        var messageAttachmentHeight: CGFloat = 0.0
        var additionalHeight: CGFloat = 0.0
        
        var finalMessage = message
        if let forward = message.forwardedFrom {
            finalMessage = forward
            finalSize.height += 30
        } else if message.repliedTo != nil {
            finalSize.height += 54
        }
        
        let additionalData = getAdditional(roomMessage: finalMessage)
        
        let text = finalMessage.message as NSString?
        
        if finalMessage.attachment != nil {
            
            switch finalMessage.type {
            case .sticker:
                let attachmentFrame = fetchStickerFrame(media: finalMessage.attachment!)
                
                messageAttachmentHeight = attachmentFrame.height
                if text != nil && text != "" {
                    finalSize.height += CellSizeLimit.ConstantSizes.Media.ExtraHeightWithText
                } else {
                    finalSize.height += CellSizeLimit.ConstantSizes.Media.ExtraHeight
                }
                
                finalSize.height += attachmentFrame.height
                finalSize.width = attachmentFrame.width
                break
                
            case .image, .imageAndText, .video, .videoAndText, .gif, .gifAndText:
                let attachmentFrame = fetchMediaFrame(media: finalMessage.attachment!)
                
                messageAttachmentHeight = attachmentFrame.height
                if text != nil && text != "" {
                    finalSize.height += CellSizeLimit.ConstantSizes.Media.ExtraHeightWithText
                } else {
                    finalSize.height += CellSizeLimit.ConstantSizes.Media.ExtraHeight
                }
                
                finalSize.height += attachmentFrame.height
                finalSize.width = attachmentFrame.width
                break
                
            case .audio, .audioAndText:
                finalSize.width = CellSizeLimit.ConstantSizes.Audio.Width
                finalSize.height += CellSizeLimit.ConstantSizes.Audio.Height
                break
                
            case .voice:
                finalSize.width = CellSizeLimit.ConstantSizes.Voice.Width
                finalSize.height += CellSizeLimit.ConstantSizes.Voice.Height
                break
                
            case .file, .fileAndText:
                finalSize.width = CellSizeLimit.ConstantSizes.File.Width
                finalSize.height += CellSizeLimit.ConstantSizes.File.Height
                break
                
            default:
                finalSize.width = 200
                finalSize.height = 50
                break
            }
        
            if text != nil && text != "" {
                let stringRect = CellSizeCalculator.bodyRect(text: text!, width: finalSize.width, isEdited: finalMessage.isEdited, extraHeight: needExtraHeight(room: room, message: message))
                finalSize.height += stringRect.height
            }
            
        } else if finalMessage.type == .wallet {
            
            if finalMessage.wallet?.type == IGPRoomMessageWallet.IGPType.moneyTransfer.rawValue {
                finalSize.height = CellSizeLimit.ConstantSizes.MoneyTransfer.Height
                finalSize.width = CellSizeLimit.ConstantSizes.MoneyTransfer.Width

                /* increase wallet description height if has data */
                if let walletDescription = finalMessage.wallet?.moneyTrasfer?.walletDescription, !walletDescription.isEmpty {
                    let descriptionWidth = CellSizeLimit.ConstantSizes.MoneyTransfer.Width - 40 // '40' is margin from left & right for description label
                    let walletDescriptionSize = CellSizeCalculator.bodyRect(text: walletDescription as NSString, width: descriptionWidth, isEdited: false, extraHeight: needExtraHeight(room: room, message: message))
                    finalSize.height += walletDescriptionSize.height
                    // Hint: use "messageAttachmentHeight" for description height in "MoneyTransferCell"
                    messageAttachmentHeight = walletDescriptionSize.height
                }
                
            } else if finalMessage.wallet?.type == IGPRoomMessageWallet.IGPType.payment.rawValue {
                finalSize.height = CellSizeLimit.ConstantSizes.Payment.Height
                finalSize.width = CellSizeLimit.ConstantSizes.Payment.Width
                
                /* increase wallet description height if has data */
                if let paymentDescription = finalMessage.wallet?.payment?.walletDescription, !paymentDescription.isEmpty {
                    let descriptionWidth = CellSizeLimit.ConstantSizes.Payment.Width - 40 // '40' is margin from left & right for description label
                    let paymentDescriptionSize = CellSizeCalculator.bodyRect(text: paymentDescription as NSString, width: descriptionWidth, isEdited: false, extraHeight: needExtraHeight(room: room, message: message))
                    finalSize.height += paymentDescriptionSize.height
                    // Hint: use "messageAttachmentHeight" for description height in "PaymentCell"
                    messageAttachmentHeight = paymentDescriptionSize.height
                }
                
            } else if finalMessage.wallet?.type == IGPRoomMessageWallet.IGPType.cardToCard.rawValue {
                finalSize.height = CellSizeLimit.ConstantSizes.CardToCard.Height
                finalSize.width = CellSizeLimit.ConstantSizes.CardToCard.Width
            }
            
        } else if finalMessage.type == .log {
            finalSize.height = CellSizeLimit.ConstantSizes.Log.Height
            
        } else if finalMessage.type == .unread {
            finalSize.height = CellSizeLimit.ConstantSizes.Unread.Height
            finalSize.width = CellSizeLimit.ConstantSizes.Unread.Width
            
        } else if finalMessage.type == .contact {
            let contactHeight = ContactCell.getContactHeight(finalMessage.contact!)
            finalSize.width = CellSizeLimit.ConstantSizes.Contact.Width
            finalSize.height += CellSizeLimit.ConstantSizes.Contact.Height
            finalSize.height += contactHeight
            
        } else if finalMessage.type == .location {
            finalSize.width = CellSizeLimit.ConstantSizes.Location.Width
            finalSize.height += CellSizeLimit.ConstantSizes.Location.Height
            finalSize.height += CellSizeLimit.ConstantSizes.Media.ExtraHeight
            messageAttachmentHeight = CellSizeLimit.ConstantSizes.Location.Height
            
        } else if finalMessage.type == .text { // Text Message
            if text != nil && text != "" {
                let stringRect = CellSizeCalculator.bodyRect(text: text!, isEdited: finalMessage.isEdited, extraHeight: needExtraHeight(room: room, message: message))
                finalSize.height += CellSizeLimit.ConstantSizes.Text.Height
                if additionalData != nil {
                    finalSize.height += stringRect.height + 110

                } else {
                    finalSize.height += stringRect.height

                }
                
                var minimumSize = CellSizeLimit.ConstantSizes.Bubble.Width.Minimum.Text
                if additionalData != nil {
                    minimumSize = CellSizeLimit.ConstantSizes.Bubble.Width.Minimum.Additional
                }
                if stringRect.width < minimumSize {
                    finalSize.width = minimumSize
                } else {
                    finalSize.width = stringRect.width
                }
                
                /** if current text size is lower than max size check 'reply' & 'forward' text size for make text box with bigger width if needed */
                if finalSize.width < CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text {
                    if let reply = message.repliedTo {
                        let message = reply.message
                        var replyMessage = message
                        if reply.attachment != nil {
                            replyMessage = "******************************"
                        }
                        var replyWidth = replyMessage!.width(withConstrainedHeight: 15, font: UIFont.igFont(ofSize: 12.0, weight: .bold))
                        if replyWidth > CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text {
                            replyWidth = CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text
                        }
                        if finalSize.width < replyWidth {
                            finalSize.width = replyWidth
                        }
                    } else if message.forwardedFrom != nil {
                        // for find best width should be fetch forward author name
                        let forwardMessage = "******************************"
                        var forwardWidth = forwardMessage.width(withConstrainedHeight: 15, font: UIFont.igFont(ofSize: 12.0, weight: .bold))
                        if forwardWidth > CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text {
                            forwardWidth = CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text
                        }
                        if finalSize.width < forwardWidth {
                            finalSize.width = forwardWidth
                        }
                    }
                }
            }
        } else {
            finalSize.width = 200
            finalSize.height = 50
        }
        
        if message.forwardedFrom == nil && additionalData != nil {
            let rowCount = IGHelperJson.getAdditionalButtonRowCount(data: additionalData!)
            additionalHeight = IGHelperBot.shared.computeHeight(rowCount: CGFloat(rowCount))
            if rowCount > 1 {
                additionalHeight += (IGHelperBot.shared.OUT_LAYOUT_SPACE * 2)
            }
        }
        
        let result = (finalSize, messageAttachmentHeight, additionalHeight)
        cache.setObject(result as AnyObject, forKey: cacheKey)
        return result
    }
    
    func getAdditional(roomMessage: IGRoomMessage) -> String? {
        if let additionalData = roomMessage.additional?.data, roomMessage.additional?.dataType == AdditionalType.UNDER_MESSAGE_BUTTON.rawValue {
            return additionalData
        }
        if let additionalDataCard = roomMessage.additional?.data, roomMessage.additional?.dataType == AdditionalType.CARD_TO_CARD_PAY.rawValue {
            return additionalDataCard
        }
        return nil
    }
    
    class func getStringStyle() -> [String: Any]{
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        return [convertFromNSAttributedStringKey(NSAttributedString.Key.font): computeSizeFont(), convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraph]
    }
    
    class func bodyRect(text: NSString, width:CGFloat=CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text, isEdited: Bool, extraHeight: Bool) -> CGSize {
        
        let fakeMinusWidth: CGFloat = 20
        var maxWidth = width
        if maxWidth > CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text {
            maxWidth = CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Text
        }
        
        var textWithTime = text as String
        textWithTime = textWithTime.replacingOccurrences(of: "**", with: "")
        if textWithTime.isRTL() {
            textWithTime = textWithTime.appending("xxx")
        } else {
            if isEdited {
                textWithTime = textWithTime.appending("xxxxxxxxxxxxxxxxxxx") // e.g. 12:00 edited
            } else {
                textWithTime = textWithTime.appending("xxxxxxxxxx") // e.g. 12:00
            }
        }
        
        var stringRect = textWithTime.boundingRect(
            with: CGSize(width: maxWidth - fakeMinusWidth , height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: convertToOptionalNSAttributedStringKeyDictionary(getStringStyle()), context: nil)
        
        if textWithTime.isRTL() {
            
            if isEdited {
                /* if width of messge is lower than minimum size for edited message,
                 * set minimum value for avoid from show a part of edited message at bubble
                 * HINT: don't append '*' to 'textWithTime' field for manage rtl edited message, because there may be an extra line
                 */
                if stringRect.size.width < CellSizeLimit.ConstantSizes.Bubble.Width.Minimum.editedRTL {
                    stringRect.size.width = CellSizeLimit.ConstantSizes.Bubble.Width.Minimum.editedRTL
                }
            }
            stringRect.size.height = stringRect.height + CGFloat(EXTRA_HEIGHT_RTL_OR_VOTE)
        } else if extraHeight {
            stringRect.size.height = stringRect.height + CGFloat(EXTRA_HEIGHT_RTL_OR_VOTE)
        }
        
        // increase width size for avoid from break line at make view due to leading & trailing params
        stringRect.size.width = stringRect.size.width + fakeMinusWidth + 6
        stringRect.size.height = stringRect.size.height + 6
        
        return stringRect.size
    }
    
    /**
     * if room type is channel or if forwarded a message from channel should be
     * set extra height at message for show view currectly after add vote items
     */
    private func needExtraHeight(room: IGRoom, message: IGRoomMessage) -> Bool {
        return (room.type == .channel || (message.forwardedFrom?.channelExtra != nil))
    }
    
    func fetchMediaFrame(media: IGFile) -> CGSize {
        return mediaFrame(media: media,
                          maxWidth:  CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Attachment,
                          maxHeight: CellSizeLimit.ConstantSizes.Bubble.Height.Maximum.Attachment,
                          minWidth:  CellSizeLimit.ConstantSizes.Bubble.Width.Minimum.Attachment,
                          minHeight: CellSizeLimit.ConstantSizes.Bubble.Height.Minimum.Attachment)
        
    }
    
    func fetchStickerFrame(media: IGFile) -> CGSize {
        return mediaFrame(media: media,
                          maxWidth:  CellSizeLimit.ConstantSizes.Bubble.Width.Maximum.Sticker,
                          maxHeight: CellSizeLimit.ConstantSizes.Bubble.Height.Maximum.Attachment,
                          minWidth:  CellSizeLimit.ConstantSizes.Bubble.Width.Minimum.Sticker,
                          minHeight: CellSizeLimit.ConstantSizes.Bubble.Height.Minimum.Attachment)
        
    }
    
    func mediaFrame(media: IGFile, maxWidth: CGFloat, maxHeight: CGFloat, minWidth: CGFloat, minHeight: CGFloat) -> CGSize {
        if media.width != 0 && media.height != 0 {
            var width = CGFloat(media.width)
            var height = CGFloat(media.height)
            if width > maxWidth && height > maxHeight {
                if width/maxWidth > height/maxHeight {
                    height = height * maxWidth/width
                    width = maxWidth
                } else {
                    width = width * maxHeight/height
                    height = maxHeight
                }
            } else if width > maxWidth {
                height = height * maxWidth/width
                width = maxWidth
            } else if height > maxHeight {
                width = width * maxHeight/height
                height = maxHeight
            }
            width  = max(width, minWidth)
            height = max(height, minHeight)
            return CGSize(width: width, height: height)
        } else {
            return CGSize(width: minWidth, height: minHeight)
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
