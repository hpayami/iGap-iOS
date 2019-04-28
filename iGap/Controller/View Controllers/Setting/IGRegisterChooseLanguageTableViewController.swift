//
//  IGRegisterChooseLanguageTableViewController.swift
//  iGap
//
//  Created by BenyaminMokhtarpour on 4/27/19.
//  Copyright © 2019 Kianiranian STDG -www.kianiranian.com. All rights reserved.
//

import UIKit

class IGRegisterChooseLanguageTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        initNavigationBar()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UITableView.appearance().semanticContentAttribute = .forceLeftToRight
        
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 50))
        //        label.textColor = UIColor.red
        label.text = "Choose Language - انتخاب زبان"
        
        label.font = UIFont.igFont(ofSize: 15)
        label.textAlignment = .center
        
        return label
        
        
    }
    func initNavigationBar(){
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: nil, title: " ")
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
        
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
            
        case 0 :
        
                SMLangUtil.changeLanguage(newLang: SMLangUtil.SMLanguage.Persian.rawValue)
                UITableView.appearance().semanticContentAttribute = .forceRightToLeft

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kIGGoDissmissLangFANotificationName), object: nil)

            
        case 1:
           
                SMLangUtil.changeLanguage(newLang: SMLangUtil.SMLanguage.English.rawValue)
                UITableView.appearance().semanticContentAttribute = .forceLeftToRight

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kIGGoDissmissLangENNotificationName), object: nil)

            
            
        case 2:
            
                SMLangUtil.changeLanguage(newLang: SMLangUtil.SMLanguage.Persian.rawValue)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kIGGoDissmissLangARNotificationName), object: nil)

            
        default :
            break
        }
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
