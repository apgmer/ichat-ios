//
//  FamilyHelper.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/18.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class FamilyHelper: NSObject {
    

    
    func getFamilyInfo(fid:String,complete:@escaping ([User]) -> ()){
        
        let reqUrl = "\(ApiConstant.SERVER_URL)familyInfos?fid=\(fid)"
//        let para :Parameters = ["fid":fid]
        Alamofire.request(reqUrl, method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
            switch response.result{
            case .success(let value):
                var allUser = [User]()
                
                let json = JSON(value)
                for(_,subJson):(String,JSON) in json["data"]{
                    let u = User(jsonData: subJson["familyUserEntity"])
                    u.status = subJson["status"].stringValue
                    let nowUser = LoginHelper.getLogUser();
                    if(nowUser.id != u.id){
                        allUser.append(u);
                    }

                }
                
                complete(allUser)
                
            case .failure(let error):
                print(error)
                complete([])
            
            }
        }
    }
    
    
}
