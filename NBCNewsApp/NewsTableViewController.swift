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
    var breakingStoryCount = 0
    var spinner: UIActivityIndicatorView!
    var header: String = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let backgroundImageName = "nbcbackground.jpg"
        let backgroundImage = UIImage(named: backgroundImageName)
        let backgroundView = UIImageView(image: backgroundImage!)
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.frame = self.view.frame
        backgroundView.alpha = 0.5
        self.tableView.backgroundView = backgroundView
        
        self.tableView.bounces = false
        
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
                    for story in items{
                        let storyObj = NewsStoryObject.init(fromDictionary:story, delegate: self)
                        //store breaking stories in a separate array
                        //breaking stories will be stored in special tableview cell
                        if storyObj.breaking == true{
                            self.stories.insert(storyObj, at: 0)
                            self.breakingStoryCount = self.breakingStoryCount + 1
                        }
                        else{
                            self.stories.append(storyObj)
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

    func createSlideShow() {
        
    }
    //reload the data when a new image is downloaded
    func imageDownloaded() {
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stories.count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath)
        cell.backgroundColor = .clear
        let story = self.stories[indexPath.row]

        cell.textLabel?.text = story.headline
        
        //add placeholder image to properly size the imageview
        cell.imageView?.image = UIImage(named: "clearplaceholder.png")
        
        var cellImage : UIImage
        if story.tease != nil {
            cellImage = story.tease!
        }
        else{
            //return the cell
            //my placeholder did not look great
            return cell
        }
        let cellImageView = UIImageView(image: cellImage)
        cellImageView.contentMode = .scaleAspectFill
        cellImageView.frame = CGRect(x: 0, y: 0, width: (cell.imageView?.frame.width)!, height: (cell.imageView?.frame.height)!)
        cellImageView.clipsToBounds = true
        cell.imageView?.addSubview(cellImageView)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let story = stories[indexPath.row]
        if let url = URL(string: story.url!){
            let vc = UIViewController()
            vc.modalPresentationStyle = UIModalPresentationStyle.popover
            
            let header = UIView(frame: CGRect(x: 0, y: 0, width: vc.view.frame.size.width, height: 60))
            header.backgroundColor = .lightGray
            vc.view.addSubview(header)
            
            let webView = UIWebView(frame: CGRect(x: 0, y: 60, width: self.view.frame.size.width, height:  self.view.frame.size.height-60))
            let request = URLRequest(url: url)
            webView.loadRequest(request)
            vc.view.addSubview(webView)
            
            let button = UIButton(type: .system)
            button.frame =  CGRect(x: 10, y: 25, width: 60, height: 40)
            button.setTitle("Done", for: .normal)
            button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            header.addSubview(button)
            
            present(vc, animated: true, completion: nil)
            
            let popoverPresentationController = vc.popoverPresentationController
            popoverPresentationController?.sourceView = self.view
        }
    }
    
    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
