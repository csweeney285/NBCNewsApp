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
protocol NewsStoryDelegate: class {
    func imageDownloaded()
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
    var teaseUrl: String?

    
    weak var delegate: NewsStoryDelegate?
    
    
    init(fromDictionary dict: Dictionary <String, Any> , delegate: NewsStoryDelegate) {
        super.init()
        self.delegate = delegate
        
        var headline = ""
        
        breaking = dict["breaking"] as? Bool
        if breaking == true {
            headline = "Breaking: "
        }
        
        id = dict["id"] as? String
        if dict["type"] as? String == "article"{
            type = .article
        }
        else{
            headline = String(format:"%@Video: ",headline)
            type = .video
        }
        self.headline = String(format:"%@%@",headline, (dict["headline"] as? String)!)
        
        published = dict["published"] as? Date
        summary = dict["summary"] as? String
        
        //save the url for when the image needs to be downloaded
        url = dict["url"] as? String
        teaseUrl = dict["tease"] as? String
    }
    
    func downloadImage()  {
        //download the image
        //will send a notification or fire a delegate to reload the table view data
        if (self.teaseUrl != nil){
            let url = URL.init(string: self.teaseUrl!)
            DispatchQueue.global(qos: .background).async {
                let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                    guard let data = data, error == nil else {
                        print("Error: \(String(describing: error))")
                        return
                    }
                    if self.type == .video{
                        //add video image on top
                        self.tease = self.addVideoImage(data: data)
                    }
                    else{
                        self.tease = UIImage(data: data)
                    }
                    //fire the delegate on the main thread since it has ui implications
                    DispatchQueue.main.async() {
                        self.delegate?.imageDownloaded()
                    }
                }
                task.resume()
            }
        }
    }
    
    func addVideoImage(data: Data) -> UIImage {
        let videoImage =  #imageLiteral(resourceName: "playbutton.png")
        if let originalImage = UIImage(data: data){
            
            UIGraphicsBeginImageContextWithOptions((originalImage.size), false, 0.0)
            originalImage.draw(in: CGRect(x: 0, y: 0, width: (originalImage.size.width), height: (originalImage.size.height)))
            videoImage.draw(in: CGRect(x: (originalImage.size.width)/2 - (originalImage.size.height)/2, y: 0, width: (originalImage.size.height), height: (originalImage.size.height)))
            
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return result!
        }
        return videoImage
    }
}


