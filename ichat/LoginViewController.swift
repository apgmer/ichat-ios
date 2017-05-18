//
//  LoginViewController.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/18.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import UIKit
import MBProgressHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var phoneText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passText.isSecureTextEntry = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logAct(_ sender: Any) {
        
        guard let phone = self.phoneText.text else {
            return
        }
        guard let pass = self.passText.text else {
            return
        }

        self.showHud(text: "正在登陆")
        let loginHelper = LoginHelper()
        loginHelper.login(phone: phone, userpwd: pass) { (res) in
            self.hideHud()
            if res{
                self.showHudWithDely(text: "登陆成功",dely: 1)
                self.junpToFamily()
            }else{
                self.showHudWithDely(text: "登陆失败，用户名密码错误",dely: 1)
            }
        }
    }
    
    func junpToFamily() -> Void {
        let familyVC = FamilyTableViewController();

        let nav = UINavigationController(rootViewController: familyVC)
        self.present(nav, animated: true, completion: nil)
        
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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
