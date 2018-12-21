//
//  ViewController.swift
//  FHIRcastAdapter_macOS
//
//  Created by Martin Bellehumeur on 21.12.18.
//  Copyright © 2018 Martin Bellehumeur. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBAction func subscribeClick(_ sender: Any) {
        
        let subscribeURL = URL(string: hubURL.stringValue)!
        let session = URLSession.shared
        var request = URLRequest(url: subscribeURL)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        var postString  = "hub.mode="+"subscribe"
        postString += "&hub.events=open-imaging-study"
        postString += "&hub.secret=secert"
        postString += "&hub.topic=12345"
        postString += "&hub.lease=999"
        postString += "&hub.channel.type=websocket"
        postString += "&hub.channel.endpoint=12345"
        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error = \(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        })
        
        task.resume()
    }
    @IBOutlet weak var hubURL: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

