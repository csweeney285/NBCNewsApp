//
//  NewsTableViewCell.swift
//  NBCNewsApp
//
//  Created by Conor Sweeney on 3/1/18.
//  Copyright © 2018 Conor Sweeney. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    @IBOutlet weak var articleImageView: UIImageView!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var headlineLabel: UILabel!
    
    func customizeCell(story: NewsStoryObject , scrolling: Bool){
        self.backgroundColor = .clear
        
        //check to see if the tease image is already downloaded if so add it to the image view
        if story.tease != nil {
            articleImageView.image = story.tease!
        }
        else if scrolling == false{
            //if we are not scrolling that means that this article is in view so lazy download the image
            story.downloadImage()
        }
        self.headlineLabel?.text = story.headline
        
        if story.type == .video {
            self.headlineLabel?.textColor = .red
            videoImageView.alpha = 1.0
        }
        else{
            self.headlineLabel?.textColor = .black
            videoImageView.alpha = 0.0
        }
    }
}
