//
//  NewsStoryObject.swift
//  NBCNewsApp
//
//  Created by Conor Sweeney on 2/26/18.
//  Copyright © 2018 Conor Sweeney. All rights reserved.
//

import UIKit

enum contentType {
    case article
    case video
}

class NewsStoryObject: NSObject {
    
    var id: String?
    var headline: String?
    var type: contentType?
    var url: String?
    var published: Date?
    var summary: String?
    var breaking: Bool?
    var tease: UIImage?
    
    init(fromDictionary dict: Dictionary <String, Any>) {
        super.init()
        id = dict["id"] as? String
        headline = dict["headline"] as? String
        
        if dict["type"] as? String == "article"{
            type = .article
        }
        else{
            type = .video
        }
        
        published = dict["published"] as? Date
        summary = dict["summary"] as? String
        breaking = dict["breaking"] as? Bool
        
        //download the image
        //will send a notification or fire a delegate to reload the table view data
        if let url = dict["tease"] as? URL{
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async() {
                    self.tease = UIImage(data: data)
                }
            }
            task.resume()
        }
    }
}
