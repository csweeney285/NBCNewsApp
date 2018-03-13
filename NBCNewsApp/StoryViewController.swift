//
//  StoryViewController.swift
//  NBCNewsApp
//
//  Created by Conor Sweeney on 3/1/18.
//  Copyright © 2018 Conor Sweeney. All rights reserved.
//

import UIKit
import WebKit

class StoryViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBAction func closeButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadUrl(url: URL) {
        self.viewDidLoad()
        let request = URLRequest(url: url)
        webView.load(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
