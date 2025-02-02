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

protocol IGMessageCollectionViewDataSource : UICollectionViewDataSource {
    func collectionView(_ collectionView: IGMessageCollectionView, messageAt indexpath: IndexPath) -> IGRoomMessage
}

class IGMessageCollectionView: UICollectionView {
    
    let layout = IGMessageCollectionViewFlowLayout()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureCollectionView()
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        configureCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureCollectionView()
    }
    
    func configureCollectionView() {
        
        self.backgroundColor = UIColor.clear
        self.keyboardDismissMode = .interactive
        self.alwaysBounceVertical = true
        self.bounces = true
        
        self.setCollectionViewLayout(layout, animated: true)
        self.register(TextCell.nib(), forCellWithReuseIdentifier: TextCell.cellReuseIdentifier())
        self.register(ImageCell.nib(), forCellWithReuseIdentifier: ImageCell.cellReuseIdentifier())
        self.register(VideoCell.nib(), forCellWithReuseIdentifier: VideoCell.cellReuseIdentifier())
        self.register(GifCell.nib(), forCellWithReuseIdentifier: GifCell.cellReuseIdentifier())
        self.register(ContactCell.nib(), forCellWithReuseIdentifier: ContactCell.cellReuseIdentifier())
        self.register(FileCell.nib(), forCellWithReuseIdentifier: FileCell.cellReuseIdentifier())
        self.register(VoiceCell.nib(), forCellWithReuseIdentifier: VoiceCell.cellReuseIdentifier())
        self.register(AudioCell.nib(), forCellWithReuseIdentifier: AudioCell.cellReuseIdentifier())
        self.register(LocationCell.nib(), forCellWithReuseIdentifier: LocationCell.cellReuseIdentifier())
        self.register(StickerCell.nib(), forCellWithReuseIdentifier: StickerCell.cellReuseIdentifier())
        self.register(MoneyTransferCell.nib(), forCellWithReuseIdentifier: MoneyTransferCell.cellReuseIdentifier())
        self.register(CardToCardCell.nib(), forCellWithReuseIdentifier: CardToCardCell.cellReuseIdentifier())
        self.register(PaymentCell.nib(), forCellWithReuseIdentifier: PaymentCell.cellReuseIdentifier())
        self.register(BillCell.nib(), forCellWithReuseIdentifier: BillCell.cellReuseIdentifier())
        self.register(TopupCell.nib(), forCellWithReuseIdentifier: TopupCell.cellReuseIdentifier())
        self.register(ProgressCell.nib(), forCellWithReuseIdentifier: ProgressCell.cellReuseIdentifier())
        self.register(IGMessageLogCollectionViewCell.nib(), forCellWithReuseIdentifier: IGMessageLogCollectionViewCell.cellReuseIdentifier())
        self.register(IGMessageLogCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: IGMessageLogCollectionViewCell.cellReuseIdentifier())
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return true
    }
}
