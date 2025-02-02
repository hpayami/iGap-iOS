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
import RxSwift
import RealmSwift
import IGProtoBuff
import RxCocoa
import Files

class IGAttachmentManager: NSObject {
    static let sharedManager = IGAttachmentManager()
    public var variablesCache: NSCache<NSString, BehaviorRelay<IGFile>>
    var completionStickerDic : [String : (IGFile)->() ] = [:]
    var syncroniseStickerQueue = DispatchQueue(label: "thread-safe-sticker-obj", attributes: .concurrent) // use "async(flags: .barrier)" for "writes on data"  AND  use "sync" for "read and assign value"
    
    private override init() {
        variablesCache = NSCache()
        variablesCache.countLimit = 2000
        variablesCache.name = "im.igap.cache.IGAttachmentManager"
        super.init()
    }
    
    func add(attachmentRef: ThreadSafeReference<IGFile>) {
        let realm = try! Realm()
        guard let attachment = realm.resolve(attachmentRef) else {
            return // attachment was deleted
        }
        if let primaryKeyId = attachment.cacheID {
            if attachment.status == .unknown {
                if IGGlobal.isFileExist(path: attachment.localPath, fileSize: attachment.size) {
                    attachment.downloadUploadPercent = 1.0
                    attachment.status = .ready
                } else {
                    attachment.downloadUploadPercent = 0.0
                    attachment.status = .readyToDownload
                }
            }
            if variablesCache.object(forKey: primaryKeyId as NSString) == nil {
                variablesCache.setObject(BehaviorRelay(value: attachment), forKey: (attachment.cacheID)! as NSString)
            } else {
                print ("found variablesCache \(primaryKeyId)")
            }
        }
    }
    
    func add(attachment: IGFile) {
        if let primaryKeyId = attachment.cacheID {
            if attachment.status == .unknown {
                if IGGlobal.isFileExist(path: attachment.localPath, fileSize: attachment.size) {
                    attachment.downloadUploadPercent = 1.0
                    attachment.status = .ready
                } else {
                    attachment.downloadUploadPercent = 0.0
                    attachment.status = .readyToDownload
                }
            }
            if variablesCache.object(forKey: primaryKeyId as NSString) == nil {
                variablesCache.setObject(BehaviorRelay(value: attachment.detach()), forKey: (attachment.cacheID)! as NSString)
            } else {
                print ("found variablesCache \(primaryKeyId)")
            }
        }
    }
    
    func getRxVariable(attachmentPrimaryKeyId: String) -> BehaviorRelay<IGFile>? {
        let file = variablesCache.object(forKey: attachmentPrimaryKeyId as NSString)
        return file
    }
    
    func setProgress(_ progress: Double, for attachment:IGFile) {
        if let variableInCache = variablesCache.object(forKey: attachment.cacheID! as NSString) {
            let attachment = variableInCache.value
            attachment.downloadUploadPercent = progress
            variableInCache.accept(attachment)
        }
    }
    
    func setStatus(_ status: Status, for attachment:IGFile) {
        if let variableInCache = variablesCache.object(forKey: attachment.cacheID! as NSString) {
            let attachment = variableInCache.value
            attachment.status = status
            variableInCache.accept(attachment)
        }
    }
    
    /* just use this method for sticker. because we need after get info
     * from server set file type, and file type detection is impossible.
     * for example detect current file info is for image or sticker ?!
     */
    func getStickerFileInfo(token: String, completion: @escaping ((_ file :IGFile) -> Void)){
        let realm = try! Realm()
        let predicate = NSPredicate(format: "token = %@", token)
        if let fileInfo = realm.objects(IGFile.self).filter(predicate).first {
            completion(fileInfo)
        } else {
            self.syncroniseStickerQueue.async(flags: .barrier) {
                self.completionStickerDic[token] = completion
            }
            IGFileInfoRequest.Generator.generate(token: token).success ({ (protoMessage) in
                if let fileInfoReponse = protoMessage as? IGPFileInfoResponse {
                    IGFactory.shared.addStickerFileToDatabse(igpFile: fileInfoReponse.igpFile, completion: { (file) -> Void in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let newFile = IGFile.putOrUpdate(igpFile: file, fileType: .sticker, filePathType: .sticker, unmanagedObjects: true)
                            
                            var completionFinal: ((_ file :IGFile) -> Void)?
                            self.syncroniseStickerQueue.sync {
                                if let completionDic = self.completionStickerDic[newFile.token!] {
                                    completionFinal = completionDic
                                    self.completionStickerDic.removeValue(forKey: newFile.token!)
                                }
                            }
                            completionFinal?(newFile)
                        }
                    })
                }
            }).error({ (errorCode, waitTime) in }).send()
        }
    }
    
    func getFileInfo(token: String, PreviewType: Int = PreviewType.originalFile.rawValue) -> IGFile? {
        return try! Realm().objects(IGFile.self).filter(NSPredicate(format: "token = %@", token)).first
    }
    
    func saveDataToDisk(attachment: IGFile) -> String? {
        if let writePath = attachment.localUrl {
            do {
                let folder = try Folder(path: writePath.deletingLastPathComponent().path)
                try folder.createFileIfNeeded(at: writePath.lastPathComponent, contents: attachment.data)
                return writePath.lastPathComponent
            } catch let error {
                print(error)
                return nil
            }
        }
        return nil
    }
    
    func appendDataToDisk(attachment: IGFile, data: Data) {
        if let url = attachment.localUrl, let outputStream = OutputStream(url: url, append: true) {
            outputStream.open()
            let bytesWritten = outputStream.write(data.bytes, maxLength: data.count)
            if bytesWritten < 0 {
                print("write failure")
            }
            outputStream.close()
        } else {
            print("unable to open file")
        }
    }
    
    func convertFileSize(sizeInByte : Int64) -> String {
        if sizeInByte == 0 {
            return ""
        } else if sizeInByte < 1024 { // Byte
            return "\(sizeInByte)".inLocalizedLanguage() + IGStringsManager.Byte.rawValue.localized
        } else if sizeInByte < 1048576 { // KB
            let size: Double = Double(sizeInByte) / 1024.0
            return String(format: "%.2f" + IGStringsManager.KB.rawValue.localized, size).inLocalizedLanguage()
        } else if sizeInByte < 1073741824 { // MB
            let size: Double = Double(sizeInByte) / 1048576.0
            return String(format: "%.2f" + IGStringsManager.MB.rawValue.localized, size).inLocalizedLanguage()
        } else { // GB
            let size: Double = Double(sizeInByte) / 1073741824.0
            return String(format: "%.2f" + IGStringsManager.GB.rawValue.localized, size).inLocalizedLanguage()
        }
    }
    
    func convertFileTime(seconds: Int) -> String{
        var time = ""
        var secondTime = seconds
        
        let hour = seconds / 3600
        let minute = seconds / 60
        
        if hour > 0 {
             secondTime = secondTime % 3600
            if hour > 9 {
                time += "\(hour):"
            } else {
                time += "0\(hour):"
            }
        }
        
        if minute > 0 {
            secondTime = secondTime % 60
            if minute > 9 {
                time += "\(minute):"
            } else {
                time += "0\(minute):"
            }
        } else {
            time += "00:"
        }
        
        if secondTime > 9 {
            time += "\(secondTime)"
        } else {
            time += "0\(secondTime)"
        }
        
        return time.inLocalizedLanguage()
    }
}
