//
//  ViewController.swift
//  FHIRcastAdapter_macOS
//
//  Created by Martin Bellehumeur on 21.12.18.
//

import Cocoa

class ViewController: NSViewController {

    let defaults = UserDefaults.standard
    
    @IBOutlet weak var hubURL: NSTextField!
    @IBOutlet weak var Secret: NSTextField!
    @IBOutlet weak var topic: NSTextField!
    
    @IBAction func subscribeClick(_ sender: Any) { subscribe(mode: "subscribe") }
    @IBAction func unsubscribeClick(_ sender: Any) { subscribe(mode: "unsubscribe")}

    @IBOutlet weak var open_patient_chart: NSButton!
    @IBOutlet weak var switch_patient_chart: NSButton!
    @IBOutlet weak var close_patient_chart: NSButton!
    @IBOutlet weak var open_imaging_study: NSButton!
    @IBOutlet weak var switch_imaging_study: NSButton!
    @IBOutlet weak var close_imaging_study: NSButton!
    @IBOutlet weak var logout_user: NSButton!
    @IBOutlet weak var hibernate_user: NSButton!
    
    @IBOutlet var logTextView: NSTextView!

    func log(msg: String){ logTextView.string += msg + "\n" }
    
    func subscribe(mode: String)  {
        
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
        if eventList.suffix(1) == "," { eventList.removeLast() }
        
        postString += "&hub.events=" + eventList
        postString += "&hub.secret=" + Secret.stringValue
        postString += "&hub.topic=" + topic.stringValue
        postString += "&hub.lease=999"
        postString += "&hub.channel.type=websocket"
        postString += "&hub.channel.endpoint="  + topic.stringValue
        log(msg: "Subscribing to " + hubURL.stringValue + " with events: " + eventList)
        var responseString = ""
        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error = \(String(describing: error))")
                return
            }
            //print("response = \(String(describing: response))")
            responseString = ""
            print(responseString)
       //     self.log(msg: String(describing: response))
        })
        task.resume()
        // connect websocket
        var wsURL="ws"
        if hubURL.stringValue.prefix(5) == "https" {
            wsURL += "s" + hubURL.stringValue.suffix( hubURL.stringValue.count - 5)
        }
        else {
            wsURL += hubURL.stringValue.suffix( hubURL.stringValue.count - 4)
        }
        if wsURL.suffix(1) == "/" {
            wsURL += "bind/" + topic.stringValue
        }
        else { wsURL += "/bind/" + topic.stringValue }
        print(wsURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if (defaults.bool(forKey: "open-patient-chart")) { open_patient_chart.state = .on}
          else { open_patient_chart.state = .off }
        if (defaults.bool(forKey: "switch-patient-chart")) { switch_patient_chart.state = .on}
          else { switch_patient_chart.state = .off }
        if (defaults.bool(forKey: "close-patient-chart")) { close_patient_chart.state = .on}
          else { close_patient_chart.state = .off }
        if (defaults.bool(forKey: "open-imaging-study")) { open_imaging_study.state = .on}
          else { open_imaging_study.state = .off }
        if (defaults.bool(forKey: "switch-imaging-study")) { switch_imaging_study.state = .on}
          else { switch_imaging_study.state = .off }
        if (defaults.bool(forKey: "close-imaging-study")) { close_imaging_study.state = .on}
          else { close_imaging_study.state = .off }
        if (defaults.bool(forKey: "hibernate-user")) { hibernate_user.state = .on}
        else { hibernate_user.state = .off }
        if (defaults.bool(forKey: "logout-user")) { logout_user.state = .on}
        else { logout_user.state = .off }
        hubURL.stringValue = defaults.string(forKey: "hubURL") ?? "http://localhost:3000/api/hub/"
        Secret.stringValue = defaults.string(forKey: "Secret") ?? "secret"
        topic.stringValue = randomString(length: 12)
    }
    
    @IBAction func saveSettingsClick(_ sender: Any) {
        if (open_patient_chart.state == .on)   { defaults.set(true, forKey: "open-patient-chart") }
          else { defaults.set(false, forKey: "open-patient-chart") }
        if (switch_patient_chart.state == .on)   { defaults.set(true, forKey: "switch-patient-chart") }
          else { defaults.set(false, forKey: "switch-patient-chart") }
        if (close_patient_chart.state == .on)   { defaults.set(true, forKey: "close-patient-chart") }
          else { defaults.set(false, forKey: "close-patient-chart") }
        if (open_imaging_study.state == .on)   { defaults.set(true, forKey: "open-imaging-study") }
          else { defaults.set(false, forKey: "open-imaging-study") }
        if (switch_imaging_study.state == .on)   { defaults.set(true, forKey: "switch-imaging-study") }
          else { defaults.set(false, forKey: "switch-imaging-study") }
        if (close_imaging_study.state == .on)   { defaults.set(true, forKey: "close-imaging-study") }
          else { defaults.set(false, forKey: "close-imaging-study") }
        if (hibernate_user.state == .on)   { defaults.set(true, forKey: "hibernate-user") }
          else { defaults.set(false, forKey: "hibernate-user") }
        if (logout_user.state == .on)   { defaults.set(true, forKey: "logout-user") }
          else { defaults.set(false, forKey: "logout-user") }
        defaults.set(hubURL.stringValue, forKey: "hubURL")
        defaults.set(Secret.stringValue, forKey: "Secret")
        
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

