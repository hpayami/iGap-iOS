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
import MapKit
import SwiftEventBus
import RxSwift

var isDashboardInner: Bool! = false

class IGDashboardViewController: BaseViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CLLocationManagerDelegate {
    
    static let itemCorner: CGFloat = 15
    let screenWidth = UIScreen.main.bounds.width
    public var pageId: Int32 = 0
    
    let discoveryListSerialQueue = DispatchQueue(label: "msg.igap.queue.discovery")
    private var _discoveries = [IGPDiscovery]()
    var discoveries: [IGPDiscovery] {
        get {
            discoveryListSerialQueue.sync {
                return _discoveries
            }
        }
        set {
            discoveryListSerialQueue.async(flags: .barrier) {[weak self] in
                guard let sSelf = self else {
                    return
                }
                sSelf._discoveries = newValue
            }
        }
    }
    
    let pollListSerialQueue = DispatchQueue(label: "msg.igap.queue.poll")
    private var _pollList = [IGPPoll]()
    private var pollList: [IGPPoll] {
        get {
            pollListSerialQueue.sync {
                return _pollList
            }
        }
        set {
            pollListSerialQueue.async(flags: .barrier) {[weak self] in
                guard let sSelf = self else {
                    return
                }
                sSelf._pollList = newValue
            }
        }
    }
    private var pollListInfoInner: [IGPPollField] = []
    private var refresher: UIRefreshControl!
    private let locationManager = CLLocationManager()
    static var needGetFirstPage = true
    private var pollResponse: IGPClientGetPollResponse!
    /// boolean value ehat shows if view controller is trying to get discovery items now
    var isGettingDiscovery = false
    
    /// This variable is set only whene should perform deep link and holds discovery id's that should be opened
    var deepLinkDiscoveryIds: [String]?
    var connectionStatus: IGAppManager.ConnectionStatus?
    var showChartOnly: Bool = false
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnRefresh: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.semanticContentAttribute = self.semantic
        
        eventBusInitializer()
        
        isfromPacket = false
        
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.initNavBarWithIgapIcon()

        registerCellsNib()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        self.refresher = UIRefreshControl()
        self.collectionView!.alwaysBounceVertical = true
        self.refresher.tintColor = UIColor.gray
        self.refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
        
        btnRefresh.layer.cornerRadius = 25
        btnRefresh.layer.masksToBounds = false
        btnRefresh.layer.shadowColor = UIColor.gray.cgColor
        btnRefresh.layer.shadowOffset = CGSize(width: 0, height: 0)
        btnRefresh.layer.shadowOpacity = 0.3
        
        if IGGlobal.shouldShowChart {
            getPollRequest()
        } else {
            getDiscoveryList()
        }
        
        IGHelperTracker.shared.sendTracker(trackerTag: IGHelperTracker.shared.TRACKER_DISCOVERY_PAGE)
        initFont()
                
        SwiftEventBus.onMainThread(self, name: "initTheme") { [weak self] result in
            self?.initTheme()
        }

        self.initTheme()
    }
    private func initTheme() {
        self.collectionView.backgroundColor = ThemeManager.currentTheme.TableViewBackgroundColor
        self.collectionView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        let navigationControllerr = self.navigationController as! IGNavigationController
        navigationControllerr.navigationBar.isHidden = false
        
        IGAppManager.sharedManager.connectionStatus.asObservable().subscribe(onNext: { [weak self] (connectionStatus) in
            self?.updateNavigationBarBasedOnNetworkStatus(connectionStatus)
        }, onError: { (error) in
            
        }, onCompleted: {
            
        }, onDisposed: {
            
        }).disposed(by: disposeBag)
        
        if isDashboardInner! {
            self.initNavigationBar(title: nil, rightItemText: nil) { }
        } else {
            self.initDashboardNavigationBar()
        }
        
        initFont()
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.disposeBag = DisposeBag()
    }
    
    deinit {
        print("Deinit IGDashboardViewController")
    }
    
    private func eventBusInitializer() {
        SwiftEventBus.on(self, name: EventBusManager.discoveryFetchFirstPage, queue: OperationQueue.current) { [weak self] (result) in
            if IGDashboardViewController.needGetFirstPage && self?.pageId == 0 {
                self?.getDiscoveryList()
            }
        }
        
        SwiftEventBus.on(self, name: EventBusManager.discoveryNearbyClick, queue: OperationQueue.current) { [weak self] (result) in
            self?.manageOpenMap()
        }
    }
    
    private func initFont() {
        btnRefresh.titleLabel!.font = UIFont.iGapFonticon(ofSize: 25)
        btnRefresh.setTitle("", for: .normal)
    }
    
    private func updateNavigationBarBasedOnNetworkStatus(_ status: IGAppManager.ConnectionStatus) {
        if let navigationItem = self.navigationItem as? IGNavigationItem {
            switch status {
            case .waitingForNetwork:
                navigationItem.setNavigationItemForWaitingForNetwork()
                connectionStatus = .waitingForNetwork
                IGAppManager.connectionStatusStatic = .waitingForNetwork
                break
                
            case .connecting:
                navigationItem.setNavigationItemForConnecting()
                connectionStatus = .connecting
                IGAppManager.connectionStatusStatic = .connecting
                break
                
            case .connected:
                connectionStatus = .connected
                IGAppManager.connectionStatusStatic = .connected
                break
                
            case .iGap:
                connectionStatus = .iGap
                IGAppManager.connectionStatusStatic = .iGap
                switch  currentTabIndex {
                case TabBarTab.Recent.rawValue:
                    let navItem = self.navigationItem as! IGNavigationItem
                    navItem.addModalViewItems(leftItemText: nil, rightItemText: nil, title: IGStringsManager.Phone.rawValue.localized)
                default:
                    if isDashboardInner! {
                        self.initNavigationBar(title: nil, rightItemText: nil) { }
                    } else {
                        self.initDashboardNavigationBar()
                    }
                }
                break
            }
        }
    }
    
    private func initDashboardNavigationBar() {
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.setDiscoveriesNavigationItems()
    }

    
    private func registerCellsNib() {
        self.collectionView!.register(DashboardCellUnknown.nib(), forCellWithReuseIdentifier: DashboardCellUnknown.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell0.self, forCellWithReuseIdentifier: "DashboardCell0.cellReuseIdentifier()")
        self.collectionView!.register(DashboardCell1.nib(), forCellWithReuseIdentifier: DashboardCell1.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell2.nib(), forCellWithReuseIdentifier: DashboardCell2.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell3.nib(), forCellWithReuseIdentifier: DashboardCell3.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell4.nib(), forCellWithReuseIdentifier: DashboardCell4.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell5.nib(), forCellWithReuseIdentifier: DashboardCell5.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell6.nib(), forCellWithReuseIdentifier: DashboardCell6.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell7.nib(), forCellWithReuseIdentifier: DashboardCell7.cellReuseIdentifier())
        self.collectionView!.register(DashboardCell8.nib(), forCellWithReuseIdentifier: DashboardCell8.cellReuseIdentifier())
    }
    
    @objc private func loadData() {
        if IGGlobal.shouldShowChart {
            getPollRequest()
        }
        else {
            getDiscoveryList()
        }
        stopRefresher()
    }
    
    @IBAction func btnRefresh(_ sender: UIButton) {
        if IGGlobal.shouldShowChart {
            getPollRequest()
        }
        else {
            getDiscoveryList()
        }
    }
    
    func stopRefresher() {
        self.refresher.endRefreshing()
    }
    
    //pollReq
    
    private func getPollRequest() {
        
        if !IGAppManager.sharedManager.isUserLoggiedIn() {
            return
        }
        IGGlobal.pageIDChartUpdate = pageId
        
        IGPClientGetPollRequest.Generator.generate(pageId: pageId).successPowerful({ [weak self] (protoResponse, requestWrapper) in
            if self == nil {return}
            
            if let response = protoResponse as? IGPClientGetPollResponse {
                self!.pollResponse = response
                self!.pollList = response.igpPolls
                
                var tmpPollList = response.igpPolls[self!.pollList.count-1]

                tmpPollList.igpModel = IGPDiscovery.IGPDiscoveryModel(rawValue: 7)!
                tmpPollList.igpScale = "8:8"
                tmpPollList.igpPollfields[0].igpImageurl = ""
                tmpPollList.igpPollfields[0].igpID = 99999999
                tmpPollList.igpPollfields[0].igpLabel = "نمودار"

                for elemnt in self!.pollList {
                    for elemnt in elemnt.igpPollfields {
                        if elemnt.igpClickable == true {
                            if elemnt.igpClicked == true {
                                IGGlobal.hideBarChart = false
                            }
                            self!.pollListInfoInner.append(elemnt)
                        }
                    }
                }
                
                if self!.showChartOnly {
                    self!.pollList.removeAll()
                    self!.pollList.append(tmpPollList)
                } else { }
//                self!.pollList.append(tmpPollList)

                DispatchQueue.main.async {
                    if isDashboardInner! {
                        if let navigationItem = self?.navigationItem as? IGNavigationItem {
                            navigationItem.addNavigationViewItems(rightItemText: nil, title: response.igpTitle)
                        }
                    }
                    
                    self?.collectionView.reloadData()
                }
            }
        }).error ({ [weak self] (errorCode, waitTime) in
            
            switch errorCode {
            case .timeout:
                self?.getPollRequest()
                self?.manageShowDiscovery()
            default:
                break
            }
        }).send()
    }
    
    //end
    
    func getDiscoveryList() {
        
        if isGettingDiscovery {
            return
        }
        isGettingDiscovery = true
        
        if pageId == 0 ,let discovery = IGRealmDiscovery.getDiscoveryInfo() {
            self.discoveries = discovery.igpDiscoveries
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
        
        if deepLinkDiscoveryIds != nil, deepLinkDiscoveryIds!.count > 0 {
            IGGlobal.prgShow()
        }
        
        if !IGAppManager.sharedManager.isUserLoggiedIn() {
            self.isGettingDiscovery = false
            return
        }
        
        IGClientGetDiscoveryRequest.Generator.generate(pageId: pageId).successPowerful({ [weak self] (protoResponse, requestWrapper) in
            if let response = protoResponse as? IGPClientGetDiscoveryResponse {
                self?.discoveries = response.igpDiscoveries
                
                self?.isGettingDiscovery = false
                
                /* just save first page info */
                if let request = requestWrapper.message as? IGPClientGetDiscovery, request.igpPageID == 0 {
                    IGDashboardViewController.needGetFirstPage = false
                    IGFactory.shared.addDiscoveryPageInfo(discoveryList: self?.discoveries ?? [])
                }
                
                DispatchQueue.main.async {
                    if isDashboardInner! {
                        if let navigationItem = self?.navigationItem as? IGNavigationItem {
                            navigationItem.addNavigationViewItems(rightItemText: nil, title: response.igpTitle)
                        }
                    }
                    
                    if self?.deepLinkDiscoveryIds != nil, self?.deepLinkDiscoveryIds?.count ?? 0 > 0 {
                        for discovery in self?.discoveries ?? [] {
                            if let discoveryField = discovery.igpDiscoveryfields.filter({ return $0.igpID == Int32(self?.deepLinkDiscoveryIds?.first ?? "0") }).first {
                                self?.deepLinkDiscoveryIds?.removeFirst()
                                AbstractDashboardCell.dashboardCellActionManager(discoveryInfo: discoveryField, deepLinkDiscoveryIds: self?.deepLinkDiscoveryIds ?? [])
                                break
                            }
                        }
                        IGGlobal.prgHide()
                    }
                    
                    self?.collectionView.reloadData()
                }
            }
        }).error ({ [weak self] (errorCode, waitTime) in
            switch errorCode {
            case .timeout:
                self?.getDiscoveryList()
                self?.manageShowDiscovery()
            default:
                break
            }
        }).send()
    }
    
    private func computeHeight(scale: String) -> CGFloat{
        let split = scale.split(separator: ":")
        let heightScale = NumberFormatter().number(from: split[1].description)
        let widthScale = NumberFormatter().number(from: split[0].description)
        let scale = CGFloat(truncating: heightScale!) / CGFloat(truncating: widthScale!)
        let height: CGFloat = IGGlobal.fetchUIScreen().width * scale
        return height
    }
    
    /* if user is login show collectionView, otherwise show btnRefresh */
    private func manageShowDiscovery() {
        DispatchQueue.main.async {
            if IGAppManager.sharedManager.isUserLoggiedIn() || self.pageId == 0 {
                
                self.collectionView!.isHidden = false
                self.btnRefresh!.isHidden = true
                if IGGlobal.shouldShowChart {
                    if self.pollList.count == 0 {
                        self.collectionView!.setEmptyMessage(IGStringsManager.WaitDataFetch.rawValue.localized)
                    } else {
                        self.collectionView!.restore()
                    }
                }
                else {
                    if self.discoveries.count == 0 {
                        self.collectionView!.setEmptyMessage(IGStringsManager.WaitDataFetch.rawValue.localized)
                    } else {
                        self.collectionView!.restore()
                    }
                }
                
            } else {
                self.collectionView!.isHidden = true
                self.btnRefresh!.isHidden = false
            }
        }
    }
    
    func manageOpenMap(){
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            IGHelperNearby.shared.openMap()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            IGHelperNearby.shared.openMap()
        }
    }
    
    /**************************************************************/
    /*********************** collectionView ***********************/
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if IGGlobal.shouldShowChart {
            manageShowDiscovery()
            return pollList.count
            
        }
        else {
            manageShowDiscovery()
            return discoveries.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if IGGlobal.shouldShowChart {
            
            let item = pollList[indexPath.section]
            if item.igpModel == .model1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell1.cellReuseIdentifier(), for: indexPath) as! DashboardCell1
                cell.semanticContentAttribute = semantic
                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse
                return cell
            } else if item.igpModel == .model2 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell2.cellReuseIdentifier(), for: indexPath) as! DashboardCell2
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse

                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                return cell
            } else if item.igpModel == .model3 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell3.cellReuseIdentifier(), for: indexPath) as! DashboardCell3
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse

                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                return cell
            } else if item.igpModel == .model4 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell4.cellReuseIdentifier(), for: indexPath) as! DashboardCell4
                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse

                return cell
            } else if item.igpModel == .model5 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell5.cellReuseIdentifier(), for: indexPath) as! DashboardCell5
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse
                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                return cell
            } else if item.igpModel == .model6 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell6.cellReuseIdentifier(), for: indexPath) as! DashboardCell6
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse
                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                return cell
            } else if item.igpModel == .model7 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell7.cellReuseIdentifier(), for: indexPath) as! DashboardCell7
                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse
                return cell
                
            }  else if item.igpModel == IGPDiscovery.IGPDiscoveryModel(rawValue: 7)! {

                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell8.cellReuseIdentifier(), for: indexPath) as! DashboardCell8
                cell.item = indexPath.item
                cell.dashboardIGPPoll = self.pollResponse
                cell.dashboardAbsPollInner = self.pollListInfoInner
                cell.initViewPoll(dashboard: pollList[indexPath.section].igpPollfields)
                return cell
                
            }
                
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCellUnknown.cellReuseIdentifier(), for: indexPath) as! DashboardCellUnknown
                cell.initView()
                return cell
            }
        }
        else {
            
            let item = discoveries[indexPath.section]
            if item.igpModel.rawValue == 0 {
                if item.igpDiscoveryfields[0].igpActiontype == .ivand {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardCell0.cellReuseIdentifier()", for: indexPath) as! DashboardCell0
                    cell.semanticContentAttribute = semantic
                    let discoveryFields = item.igpDiscoveryfields
                    cell.initView(dashboard: discoveryFields)
                    
                    return cell

                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell1.cellReuseIdentifier(), for: indexPath) as! DashboardCell1
                    cell.semanticContentAttribute = semantic
                    let discoveryFields = item.igpDiscoveryfields
                    cell.initView(dashboard: discoveryFields)
                    return cell

                }
                
            } else if item.igpModel.rawValue == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell2.cellReuseIdentifier(), for: indexPath) as! DashboardCell2
                
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                
                return cell
            } else if item.igpModel.rawValue == 2 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell3.cellReuseIdentifier(), for: indexPath) as! DashboardCell3
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                return cell
            } else if item.igpModel.rawValue == 3 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell4.cellReuseIdentifier(), for: indexPath) as! DashboardCell4
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                return cell
            } else if item.igpModel.rawValue == 4 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell5.cellReuseIdentifier(), for: indexPath) as! DashboardCell5
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                return cell
            } else if item.igpModel.rawValue == 5 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell6.cellReuseIdentifier(), for: indexPath) as! DashboardCell6
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                return cell
            } else if item.igpModel.rawValue == 6 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell7.cellReuseIdentifier(), for: indexPath) as! DashboardCell7
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                return cell
            }
            else if item.igpModel == IGPDiscovery.IGPDiscoveryModel(rawValue: 7)! {

                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCell8.cellReuseIdentifier(), for: indexPath) as! DashboardCell8
                let discoveryFields = item.igpDiscoveryfields
                cell.initView(dashboard: discoveryFields)
                return cell
            }
                
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardCellUnknown.cellReuseIdentifier(), for: indexPath) as! DashboardCellUnknown
                cell.initView()
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        /***** Hint: plus height with 8 ,because in storyboard we used 4 space from top and 4 space from bottom. Result is 8 but now we set 4 because seems to with this value images have better view scale *****/
        if IGGlobal.shouldShowChart {
            return CGSize(width: screenWidth, height: computeHeight(scale: pollList[indexPath.section].igpScale) + 4)
        } else {
            if discoveries[indexPath.section].igpDiscoveryfields[0].igpActiontype == IGPDiscoveryField.IGPButtonActionType.ivand {
                return CGSize(width: screenWidth, height: 82)
            }else {
                return CGSize(width: screenWidth, height: computeHeight(scale: discoveries[indexPath.section].igpScale) + 4)
            }
//            return CGSize(width: screenWidth, height: computeHeight(scale: discoveries[indexPath.section].igpScale) + 4)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.hidesBottomBarWhenPushed = true
    }
}
