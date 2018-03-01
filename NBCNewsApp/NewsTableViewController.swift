//
//  NewsTableViewController.swift
//  NBCNewsApp
//
//  Created by Conor Sweeney on 2/26/18.
//  Copyright © 2018 Conor Sweeney. All rights reserved.
//

import UIKit



class NewsTableViewController: UITableViewController, NewsStoryDelegate {
    
    //store all the stories here
    var stories: Array<NewsStoryObject> = []
    var spinner: UIActivityIndicatorView!
    var header: String = ""
    var scrolling: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        downloadArticleData()
    }
    
    func setUpView()  {
        //add spinner
        spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.frame = CGRect(x: self.view.center.x, y:self.view.center.y, width: 20.0, height: 20.0)
        spinner.startAnimating()
        self.view.addSubview(spinner)
        
        //add header to tableview
        let headerImageName = "NBCNews.png"
        let headerImage = UIImage(named: headerImageName)
        let headerView = UIImageView(image: headerImage!)
        headerView.contentMode = .scaleAspectFit
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60)
        self.tableView.tableHeaderView = headerView
        
        //add background
        let backgroundImageName = "nbcbackground.jpg"
        let backgroundImage = UIImage(named: backgroundImageName)
        let backgroundView = UIImageView(image: backgroundImage!)
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.frame = self.view.frame
        backgroundView.alpha = 0.5
        self.tableView.backgroundView = backgroundView
    }
    
    func downloadArticleData() {
        //download news data on background thread
        DispatchQueue.global(qos: .background).async {
            let url = URL(string: "http://msgviewer.nbcnewstools.net:9207/v1/query/vertical/news/")
            let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                guard let data = data else {
                    print("Error: \(String(describing: error))")
                    return
                }
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = json as? [String: Any] {
                    let items = dictionary["items"] as! [Dictionary<String, Any>]
                    //store article headlines in a dictionary which will be used as a check to avoid adding duplicate articles
                    var articleDict = [String:String]()
                    for story in items{
                        let storyObj = NewsStoryObject.init(fromDictionary:story, delegate: self)
                        if !(articleDict [storyObj.headline!] != nil){
                            if storyObj.breaking == true{
                                //store breaking stories at the front of the array so they appear first
                                self.stories.insert(storyObj, at: 0)
                            }
                            else{
                                self.stories.append(storyObj)
                            }
                            //add the headline to the dictionary to prevent duplicate article
                            articleDict[storyObj.headline!] = "true"
                        }
                    }
                    //dispatch to main thread to remove spinner and update the header
                    DispatchQueue.main.async {
                        self.spinner.removeFromSuperview()
                        self.header = (dictionary["header"] as? String)!
                        self.tableView.reloadData()
                    }
                }
            }
            task.resume()
        }
    }
    
    //reload the data when a new image is downloaded
    //this is fired by the NewsStoryObject delegate
    func imageDownloaded() {
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        removeImagesFromMemory()
    }
    
    func removeImagesFromMemory() {
        //delete all of the image data
        //store all the visible rows in a dictionary to boost performance instead of checking if a cell is within indexPathsForVisibleRows in each iteration of the for loop
        var indexDict = [String:String]()
        for number in 0..<((tableView.indexPathsForVisibleRows?.count)!-1){
            let key = String(tableView.indexPathsForVisibleRows![number].row)
            indexDict[key] = "true"
        }
        var counter = 0
        for story in self.stories{
            //check the dictionary if the cell is visible this will now run in O(n+m) instead of checking if indexPathsForVisibleRows.contains(counter) which would run in O(n*m)
            if(indexDict [String(counter)] == nil){
                story.tease = nil
            }
            counter = counter + 1
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //fetch the story that relates to the cell
        let story = self.stories[indexPath.row]

        //create cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath)
        
        return formatNewsStoryCell(story: story, cell: cell)
    }
    
    func formatNewsStoryCell(story: NewsStoryObject, cell: UITableViewCell) -> UITableViewCell {
        //create cell
        cell.backgroundColor = .clear
        
        //add placeholder image to properly size the imageview
        cell.imageView?.image = #imageLiteral(resourceName: "clearplaceholder.png")
        
        //lazy load the images for smoother scrolling
        var cellImageView = UIImageView()
        var cellVideoOverlay = UIImageView()
        //only add the subview if it does not exist
        //fetch the extra image views to change their images or alpha
        for subview in (cell.imageView?.subviews)!{
            //the image views are already in the cell no need to add them again
            if subview.tag == 1{
                cellImageView = subview as! UIImageView
            }
            else if subview.tag == 2{
                cellVideoOverlay = subview as! UIImageView
            }
        }
        
        //check to see if the tease image is already downloaded if so add it to the image view
        if story.tease != nil {
            cellImageView.image = story.tease!
        }
        else{
            //set the image to the clear placeholder to override any existing image
            cellImageView.image = #imageLiteral(resourceName: "clearplaceholder.png")
            if self.scrolling == false{
                //if we are not scrolling that means that this article is in view so lazy download the image
                story.downloadImage()
            }
        }
        
        //add the extra cell image views if it is missing
        cellImageView.contentMode = .scaleAspectFill
        cellImageView.clipsToBounds = true
        cellImageView.tag = 1
        cellImageView.frame = CGRect(x: 0, y: 0, width: (cell.imageView?.frame.width)!, height: (cell.imageView?.frame.height)!)
        cell.imageView?.addSubview(cellImageView)
        
        //add the video image on top of the image
        //i will adjust the alpha to show it
        cellVideoOverlay.contentMode = .scaleAspectFit
        cellVideoOverlay.clipsToBounds = true
        cellVideoOverlay.tag = 2
        cellVideoOverlay.image = #imageLiteral(resourceName: "playbutton.png")
        cellVideoOverlay.frame = CGRect(x: 0, y: 0, width: (cell.imageView?.frame.width)!, height: (cell.imageView?.frame.height)!)
        
        cell.imageView?.addSubview(cellVideoOverlay)
        
        //for videos
        //set the label text color to red if it is a video and black if it is an article
        //set the video image alpha to one if it is a video
        cell.textLabel?.text = story.headline
        
        if story.type == .video {
            cell.textLabel?.textColor = .red
            cellVideoOverlay.alpha = 1.0
        }
        else{
            cell.textLabel?.textColor = .black
            cellVideoOverlay.alpha = 0.0
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //fetch the NewStoryObject that was selected
        let story = stories[indexPath.row]
        if let url = URL(string: story.url!){
            presentArticleViewController(url: url)
        }
        //deselect the row so its not higlighted when you return
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Article webview
    func presentArticleViewController(url: URL) {
        //create and pop a simple presentation vc to display the url
        let vc = UIViewController()
        vc.modalPresentationStyle = UIModalPresentationStyle.popover
        
        //header
        let header = UIView(frame: CGRect(x: 0, y: 0, width: vc.view.frame.size.width, height: 60))
        header.backgroundColor = .lightGray
        vc.view.addSubview(header)
        
        //dismiss button
        let button = UIButton(type: .system)
        button.frame =  CGRect(x: 10, y: 25, width: 60, height: 40)
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        header.addSubview(button)
        
        //webview
        let webView = UIWebView(frame: CGRect(x: 0, y: 60, width: self.view.frame.size.width, height:  self.view.frame.size.height-60))
        let request = URLRequest(url: url)
        webView.loadRequest(request)
        vc.view.addSubview(webView)
        
        present(vc, animated: true, completion: nil)
        
        //this is to prevent crash for ipads
        let popoverPresentationController = vc.popoverPresentationController
        popoverPresentationController?.sourceView = self.view
    }
    
    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Scrollview delegate
    //lazy load the images to improve scrolling
    //this way we only download images for stories that are in view
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.scrolling = false
        self.tableView.reloadData()
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrolling = false
        self.tableView.reloadData()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrolling = true
    }
    
    override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.scrolling = true
    }
}
