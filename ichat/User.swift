//
//  User.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/18.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import Foundation
import SwiftyJSON
class User: NSObject {
    
    var id:String?
    var phone:String?
    var pass:String?
    var familyId:String?
    var role:String?
    var nickname:String?
    var status:String?
    
    init(jsonData:JSON) {
        
        self.id = jsonData["id"].stringValue
        self.phone = jsonData["phone"].stringValue
        self.pass = jsonData["pass"].stringValue
        self.familyId = jsonData["familyId"].stringValue
        self.role = jsonData["role"].stringValue
        self.nickname = jsonData["nickname"].stringValue
        self.status = jsonData["status"].stringValue

    }
    
    override init() {
        
    }
    
}
