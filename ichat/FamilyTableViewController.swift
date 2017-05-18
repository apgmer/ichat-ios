//
//  FamilyTableViewController.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/18.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import UIKit
import MJRefresh

class FamilyTableViewController: UITableViewController {

    var users:[User]?
    var timer:Timer?
    
    // 顶部刷新
    let header = MJRefreshNormalHeader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setOnlineTimer()
        self.title = "家庭成员"
        
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView!.register(UINib(nibName: "FamilyTableViewCell", bundle: nil), forCellReuseIdentifier: "familyTableViewCell")
        self.tableView.estimatedRowHeight = 80.0;
        self.tableView.rowHeight = UITableViewAutomaticDimension;

        // 下拉刷新
//        header.setRefreshingTarget(self, refreshingAction: #sele)
        header.setRefreshingTarget(self
            , refreshingAction: #selector(FamilyTableViewController.headerRefresh))
        // 现在的版本要用mj_header
        self.tableView.mj_header = header

    }
    func headerRefresh(){
        self.setupData()
    }

    func setupData() -> Void {
        let familyHelper = FamilyHelper()
        let u = LoginHelper.getLogUser();
        if let fid = u.familyId{
            familyHelper.getFamilyInfo(fid: fid) { (u) in
                self.users = u
                self.tableView.reloadData()
                self.tableView.mj_header.endRefreshing()

            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if self.users?.count == 0 {
            return 0
        }else{
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let u = self.users{
            return u.count
        }else{
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellId = "familyTableViewCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? FamilyTableViewCell

        if (nil == cell) {
            cell = FamilyTableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellId)
        }
        
        let data = self.users?[indexPath.row]
        
        cell?.nickname.text = data?.nickname
        cell?.phone.text = data?.phone
        cell?.uid = data?.id
        if data?.status == "ONLINE" {
            cell?.status.text = "在线"
        }else{
            cell?.status.text = "离线"
        }
        
        // Configure the cell...

        return cell!
    }
 
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatVC = ChatViewController()
        chatVC.connectedUser = self.users?[indexPath.row].id
        self.present(chatVC, animated: true, completion: nil)
    }
    
    func setOnlineTimer() -> Void {
        self.timer = Timer.scheduledTimer(timeInterval: 10,target:self,selector:#selector(FamilyTableViewController.keepOnline),userInfo:nil,repeats:true)
    }
    func keepOnline() -> Void {
        LoginHelper.keepOnlineReq()
    }

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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
