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
    
    var id: NSString?
    var type: contentType?
    var url: NSString?
    var published: Date?
    var tease: UIImage?
    var summary: NSString?
    var breaking: Bool?
    
    init(fromDictionary dict: Dictionary <String, Any>) {
        super.init()
        
    }
}
