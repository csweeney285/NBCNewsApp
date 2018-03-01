//
//  StoryViewController.swift
//  NBCNewsApp
//
//  Created by Conor Sweeney on 3/1/18.
//  Copyright © 2018 Conor Sweeney. All rights reserved.
//

import UIKit

class StoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //header
        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 60))
        header.backgroundColor = .lightGray
        self.view.addSubview(header)
        
        //dismiss button
        let button = UIButton(type: .system)
        button.frame =  CGRect(x: 10, y: 25, width: 60, height: 40)
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        header.addSubview(button)
    }
    
    func addWebView(url: URL) {
        //webview
        let webView = UIWebView(frame: CGRect(x: 0, y: 60, width: self.view.frame.size.width, height:  self.view.frame.size.height-60))
        let request = URLRequest(url: url)
        webView.loadRequest(request)
        self.view.addSubview(webView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
}
