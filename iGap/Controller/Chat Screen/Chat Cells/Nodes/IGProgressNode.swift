//
//  IGProgressNode.swift
//  iGap
//
//  Created by ahmad mohammadi on 1/26/20.
//  Copyright © 2020 Kianiranian STDG -www.kianiranian.com. All rights reserved.
//

import AsyncDisplayKit

protocol IGProgreeNodeDelegate {
    func downloadUploadIndicatorDidTap(_ indicator: IGProgressNode)
}

class IGProgressNode: ASDisplayNode {
    
    var delegate: IGProgreeNodeDelegate?
    
    private var backNode = ASDisplayNode()
    private var state: IGFile.Status = .readyToDownload {
        didSet {
            switch self.state {
            case .readyToDownload:
                setPercentage(percent: 0)
                self.txtNodePercent.isHidden = true
                self.btnChangeState.isHidden = false
                break
            case .downloading:
                self.txtNodePercent.isHidden = false
                self.btnChangeState.isHidden = true
                break
            case .uploadFailed:
                self.txtNodePercent.isHidden = true
                self.btnChangeState.isHidden = false
                break
            case .uploading:
                self.txtNodePercent.isHidden = false
                self.btnChangeState.isHidden = true
                break
            case .ready:
                self.removeFromSupernode()
                break
            case .unknown:
                setPercentage(percent: 0)
                self.txtNodePercent.isHidden = true
                self.btnChangeState.isHidden = false
                break
            }
        }
    }
    
    private var txtNodePercent = ASTextNode()
    private var btnChangeState = ASButtonNode()
    
    override init() {
        super.init()
        
        backNode.backgroundColor = UIColor(white: 0, alpha: 0.6)
        IGGlobal.makeText(for: txtNodePercent, with: "100%".inLocalizedLanguage(), textColor: UIColor.white, size: 10, numberOfLines: 1)

        
//        state = .readyToDownload
        backNode.style.width = ASDimension(unit: .points, value: 50)
        backNode.style.height = ASDimension(unit: .points, value: 50)
        backNode.layer.cornerRadius = 25
        
        txtNodePercent.style.width = ASDimension(unit: .points, value: 40)
        txtNodePercent.style.height = ASDimension(unit: .points, value: 20)

        btnChangeState.style.width = ASDimension(unit: .points, value: 40)
        btnChangeState.style.height = ASDimension(unit: .points, value: 30)
        
        addSubnode(backNode)
        addSubnode(txtNodePercent)
        addSubnode(btnChangeState)

    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        
        let backCenterAspec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: backNode)
         
        let percentCenterAspec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: txtNodePercent)
        
        let btnCenterAspec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: btnChangeState)
        
        let over1Spec = ASOverlayLayoutSpec(child: backCenterAspec, overlay: percentCenterAspec)
        let over2Spec = ASOverlayLayoutSpec(child: over1Spec, overlay: btnCenterAspec)
        
        return over2Spec
    }
    
    
    func setPercentage(percent: Int) {
        
        txtNodePercent.attributedText = NSAttributedString(string: "\(percent)%", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        
    }
    
    func setFileType(_ type: IGProgressType) {
        if type == .download {
            btnChangeState.setAttributedTitle(NSAttributedString(string: "🎚", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.font : UIFont.iGapFonticon(ofSize: 35)]), for: .normal)
//            actionButton?.setTitle("🎚", for: UIControl.State.normal)
        } else { // upload
            
            btnChangeState.setAttributedTitle(NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.font : UIFont.iGapFonticon(ofSize: 35)]), for: .normal)
//            actionButton?.setTitle("", for: UIControl.State.normal)
        }
    }
    
    func setState(_ state:IGFile.Status) {
        self.state = state
    }
    
    
    @objc func didTapOnView() {
        self.delegate?.downloadUploadIndicatorDidTap(self)
    }
    
    
}
