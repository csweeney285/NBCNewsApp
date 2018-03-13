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
    var scrolling: Bool = false
    @IBOutlet weak var headerLabel: UILabel!
    
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
        
        //add background
        //this cannot be added to a uitableviewcontroller in the story board so I'm adding it programmatically
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
                        var headerText = (dictionary["header"] as? String)!
                        if headerText.contains("NBC News -"){
                            headerText.removeFirst(10)
                        }
                        self.headerLabel.text = headerText
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath) as! NewsTableViewCell
        cell.customizeCell(story: story, scrolling: self.scrolling)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return CGFloat(44)
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
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "StoryViewController") as! StoryViewController
        controller.modalPresentationStyle = UIModalPresentationStyle.popover
        present(controller, animated: true, completion:  { () -> Void in
            controller.loadUrl(url: url)
        })
        
        //this is to prevent crash for ipads
        let popoverPresentationController = controller.popoverPresentationController
        popoverPresentationController?.sourceView = self.view
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
