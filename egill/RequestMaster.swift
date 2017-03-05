//
//  RequestMaster.swift
//  egill
//
//  Created by Valtýr Örn Kjartansson on 3/4/17.
//  Copyright © 2017 Valtýr Örn Kjartansson. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class RequestMaster: NSObject {
    
    static let rootURL = "http://egill.local"
    static let topURL = rootURL+":1994/"
    static let socketURL = rootURL+":1997/"
    
    class func sendPic(image: UIImage, id: String, num: String){
        Alamofire.upload(multipartFormData: { multipartFormData in
            if let imageData = UIImagePNGRepresentation(image){
                multipartFormData.append(imageData, withName: "image", fileName: "png", mimeType: "image/png")
                multipartFormData.append(id.data(using: .utf8)!, withName: "id")
                multipartFormData.append(num.data(using: .utf8)!, withName: "num")
            }
        }, to: topURL, encodingCompletion: {
            encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                print("s")
                upload.responseJSON {
                    response in
                    print(response.request)  // original URL request
                    print(response.response) // URL response
                    print(response.data)     // server data
                    print(response.result)   // result of response serialization
                    
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                    }
                }
            case .failure(let encodingError):
                print(encodingError)
            }
        })
            
    }
}
