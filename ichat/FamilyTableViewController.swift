//
//  FamilyTableViewController.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/18.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import UIKit
import MJRefresh
import SocketIO
import SwiftyJSON
import MBProgressHUD

class FamilyTableViewController: UITableViewController {
    var nowUser:User = LoginHelper.getLogUser();
    var socket: SocketIOClient! = nil

    var users:[User]?
    var timer:Timer?
    var requestUser:String?
    
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
        self.initSocket()
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
//        let chatVC = ChatViewController()
//        chatVC.connectedUser = self.users?[indexPath.row].id
//        self.present(chatVC, animated: true, completion: nil)
        self.sendReq(userid: (self.users?[indexPath.row].id)!)
    }
    
    
    
    func setOnlineTimer() -> Void {
        self.timer = Timer.scheduledTimer(timeInterval: 10,target:self,selector:#selector(FamilyTableViewController.keepOnline),userInfo:nil,repeats:true)
    }
    func keepOnline() -> Void {
        LoginHelper.keepOnlineReq()
    }
    func initSocket() -> Void {
        socket = SocketIOClient(socketURL: URL(string: ApiConstant.SOCKET_IO_URL)!, config: [.log(false), .forcePolling(true)])
        socket.on("connect") { data in
            let loginData:Dictionary = [
                "type":"login",
                "name":self.nowUser.id
            ]
            self.sigSend(loginData as Dictionary<String, AnyObject>)
        }
        
        socket.on("webrtcMsg") { (data, emitter) in
            if (data.count == 0) {
                return
            }
            
            let jsonStr = data[0] as! String
            if let dataFromString = jsonStr.data(using: .utf8, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                print(json);
                
                let type = json["type"].string
                
                if let t = json["name"].string{
                    self.requestUser = t;
                }
                
                if( type == "request"){
                    self.showAlert()
                }else if(type == "ok"){
//                    let chatVC = ChatViewRecvOfferController()
                    let chatVC = ChatViewController()
                    chatVC.connectedUser = self.requestUser
                    self.present(chatVC, animated: true, completion: nil)
                    self.hideHud()
                }else if(type == "refuse"){
                    self.hideHud()
                    self.showHudWithDely(text: "对方拒绝", dely: 3)
                }
            }
            
        }
        socket.connect();
    
    }
    func sigSend(_ msg:Dictionary<String,AnyObject>) {
        let sendMsg = msg;
        let str = JSON(sendMsg).rawString()
        socket.emit("webrtcMsg", str!)
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "提示",
                                      message: "您的好友请求与您通话，是否接受？",
                                      preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "同意",
                                          style: UIAlertActionStyle.default,
                                          handler:{ (action: UIAlertAction) -> Void in
                                            print("UIAlertController action :",action.title ?? "default");
                                            let ok:Dictionary = [
                                                "type":"ok",
                                                "name":self.requestUser
                                            ]
                                            self.sigSend(ok as Dictionary<String, AnyObject>)
                                            let chatVC = ChatViewController()
                                            chatVC.connectedUser = self.requestUser
                                            self.present(chatVC, animated: true, completion: nil)
        })
        
//        let cancelAction = UIAlertAction(title: "cancel",
//                                         style: UIAlertActionStyle.cancel,
//                                         handler:{ (action: UIAlertAction) -> Void in
//                                            print("UIAlertController action :", action.title ?? "cancel");
//        })
        let destructiveAction = UIAlertAction(title: "拒绝",
                                              style: UIAlertActionStyle.destructive,
                                              handler:{ (action: UIAlertAction) -> Void in
                                                print("UIAlertController action :", action.title ?? "cancel");
        })
        
        
        alert.addAction(defaultAction);
//        alert.addAction(cancelAction);
        alert.addAction(destructiveAction);
        present(alert, animated: true, completion: {
            print("UIAlertController present");
        })
    }
    
    func sendReq(userid:String) -> Void {
//        send({type: 'request',name:friendid})
        self.requestUser = userid
        let requestData:Dictionary<String,AnyObject> = [
            "type":"request" as AnyObject,
            "name":userid as AnyObject,
            "isMobile":true as AnyObject
        ]
        self.sigSend(requestData as Dictionary<String, AnyObject>);
        self.showHud(text: "已发送邀请，等待接受")

    }
    func showHud(text:String) -> Void {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = text
        hud.show(animated: true)
    }
    func hideHud() -> Void {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    func showHudWithDely(text:String,dely:TimeInterval) -> Void {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = text
        hud.hide(animated: true, afterDelay: dely)
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
