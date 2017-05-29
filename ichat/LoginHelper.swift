//
//  LoginHelper.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/18.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class LoginHelper {
    
    private let _userDefaults = UserDefaults()
    
    
    func login(phone:String,userpwd:String,complete:@escaping (Bool) -> ()) {
        let loginUrl = ApiConstant.SERVER_URL + "login"
        let para: Parameters = ["phone":phone,"pass":userpwd]
        
        Alamofire.request(loginUrl, method: .post, parameters: para,encoding: JSONEncoding.default).responseJSON { (response) in
            
            switch response.result{
            case .success:

                if let res = response.result.value{
                    let resDic = res as! NSDictionary;
                    if (resDic["success"] as! NSNumber == 1){
                        let userInfo = resDic["data"] as! NSArray
                        let data = userInfo[0] as! NSDictionary
                        do{
                            let jsonResult = try JSONSerialization.data(withJSONObject: data, options: [])
                            if let userJson = String(data:jsonResult, encoding: String.Encoding.utf8){
                                self.saveUser(userJson: userJson, passwd: userpwd)
                                complete(true)
                            }
                        }catch{
                            print("JSON Processing Failed")
                            complete(false)
                        }	
                        
                        
                    }
                }
            case .failure:
                print("fail")
                complete(false)
            }
            complete(true)
        }
    }
    
    class func getLogUser() -> User {
        let userDefaults = UserDefaults()
        let userData = userDefaults.object(forKey: "userData") as! String

        if let dataFromString = userData.data(using: .utf8, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)
            
            return User(jsonData: json)
            
            
        }

        return User()
    }
    

    /**
     保存用户到UserDefaults
     
     - parameter userModel: 用户信息
     - parameter token:     token
     */
    func saveUser(userJson:String,passwd:String) -> Void {
        _userDefaults.removeObject(forKey: "userData")
        _userDefaults.removeObject(forKey: "passwd")
        _userDefaults.synchronize()
        _userDefaults.set(userJson, forKey: "userData")
        _userDefaults.set(passwd, forKey: "passwd")
    }
    
    class func keepOnlineReq()->Void{
        let uid = LoginHelper.getLogUser().id!;
        Alamofire.request("\(ApiConstant.SERVER_URL)keepOnline?uid=\(uid)").responseJSON { (res) in
        }

    }
    
}
