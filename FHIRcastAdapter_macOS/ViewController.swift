//
//  ViewController.swift
//  FHIRcastAdapter_macOS
//
//  Created by Martin Bellehumeur on 21.12.18.
//  Copyright © 2018 Martin Bellehumeur. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
  
    @IBOutlet weak var open_patient_chart: NSButton!
    @IBOutlet weak var switch_patient_chart: NSButton!
    @IBOutlet weak var close_patient_chart: NSButton!
    @IBOutlet weak var open_imaging_study: NSButton!
    @IBOutlet weak var switch_imaging_study: NSButton!
    @IBOutlet weak var close_imaging_study: NSButton!
    @IBOutlet weak var logout_user: NSButton!
    @IBOutlet weak var hibernate_user: NSButton!
    
    @IBAction func subscribeClick(_ sender: Any) {
        
        let subscribeURL = URL(string: hubURL.stringValue)!
        let session = URLSession.shared
        var request = URLRequest(url: subscribeURL)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        var postString  = "hub.mode="+"subscribe"
        
        var eventList = "";
        if (open_patient_chart.state == .on)   { eventList += "open-patient-chart,"}
        if (switch_patient_chart.state == .on) { eventList += "switch-patient-chart,"}
        if (close_patient_chart.state == .on)  { eventList += "close-patient-chart,"}
        if (open_imaging_study.state == .on)   { eventList += "open-imaging-study,"}
        if (switch_imaging_study.state == .on) { eventList += "switch-imaging-study,"}
        if (close_imaging_study.state == .on)  { eventList += "close-imaging-study,"}
        if (hibernate_user.state == .on)       { eventList += "hibernate-user,"}
        if (logout_user.state == .on)          { eventList += "logout-user,"}

        postString += "&hub.events=" + eventList
        postString += "&hub.secret=secert"
        postString += "&hub.topic=12345"
        postString += "&hub.lease=999"
        postString += "&hub.channel.type=websocket"
        postString += "&hub.channel.endpoint=12345"

        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error = \(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
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

