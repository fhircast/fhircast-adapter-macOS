//
//  ViewController.swift
//  FHIRcastAdapter_macOS
//
//  Created by Martin Bellehumeur on 21.12.18.
//

import Cocoa

class ViewController: NSViewController {

    let defaults = UserDefaults.standard
    let ws = WebSocket()

    @IBOutlet weak var hubURL: NSTextField!
    @IBOutlet weak var Secret: NSTextField!
    @IBOutlet weak var topic: NSTextField!
    
    @IBAction func subscribeClick(_ sender: Any) { subscribe(mode: "subscribe") }
    @IBAction func unsubscribeClick(_ sender: Any) { subscribe(mode: "unsubscribe")}
    @IBAction func helpClick(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/fhircast/fhircast-adapter-macOS")!)
    }
    
    @IBAction func shutdownClick(_ sender: Any) { NSApplication.shared.terminate(self) }
    
    @IBAction func DeleteClick(_ sender: Any) { logTextView.string = "" }
    
    @IBOutlet weak var autoSubscribe: NSButton!
    @IBOutlet weak var osirix: NSButton!
    
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
        request.httpBody = postString.data(using: .utf8)
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request as URLRequest, completionHandler:
            {
                data, response, error in guard let data = data, error == nil else
                {
                    print("error = \(String(describing: error))")
                    return
                }
                print("response = \(String(describing: response))")
                print("data = \(String(describing: data))")
                semaphore.signal()
            }
        )
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        let hubComponents = self.hubURL.stringValue.split(separator: "/")
        var wsURL="ws"
        if (hubComponents[0] == "https") { wsURL += "s" }
        wsURL += "://" + hubComponents[1] + "/bind/" + self.topic.stringValue
        log(msg: "Binding websocket: " + wsURL)
        ws.open(wsURL)
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
        
        if (defaults.bool(forKey: "auto-subscribe")) { autoSubscribe.state = .on}
          else { autoSubscribe.state = .off }
        if (defaults.bool(forKey: "osirix")) { osirix.state = .on}
          else { osirix.state = .off }

        ws.event.open = { self.log(msg: "websocket opened") }
        ws.event.close = { code, reason, clean in self.log(msg: "websocket close") }
        ws.event.error = { error in self.log(msg: "websocket error \(error)") }
        ws.event.message = { message in
            if let text = message as? String {
                if text.range(of:"bound") != nil {
                    self.log(msg: "websocket acknowleged by hub.")
                }
                else {
                    self.log(msg: "recv: \(text)")
                    self.handleEvent(msg: text)
                }
                //self.launchOsirix(command: "DisplayStudy", studyUID: "1.2.840.113619.2.1.2.139348932.602501178")
            }
        }
        
        if (autoSubscribe.state == .on) { subscribe(mode: "subscribe") }
    }
    
    func handleEvent(msg: String) {
        
        struct fhircast: Codable {
            var timestamp: String
            var id: String
            var eventDescription: eventStructure
            enum CodingKeys: String, CodingKey {
                case timestamp
                case id
                case eventDescription = "event"
            }
        }
        struct eventStructure: Codable {
            var hubEvent: String
            var hubTopic: String
            var context: [contextStructure]
            enum CodingKeys:  String, CodingKey {
                case hubEvent = "hub.event"
                case hubTopic = "hub.topic"
                case context
            }
        }
        struct contextStructure: Codable {
            var key: String
            var resource: resourceStructure
        }
        struct resourceStructure: Codable {
            var id: String
            var resourceType: String
            var identifier: [identifierStructure]
            
        }
        struct identifierStructure: Codable {
            var system: String
            var value: String
        }
 
        let jsonData = msg.data(using: .utf8)!
        let decoder = JSONDecoder()
        let fhicastEvent = try! decoder.decode(fhircast.self, from: jsonData)
        
        
        let eventName = fhicastEvent.eventDescription.hubEvent
        var accessionNumber = ""
        for context in fhicastEvent.eventDescription.context  {
            if (context.key == "study"){
                accessionNumber=context.resource.identifier[0].value
            }
        }
        log(msg:"Received event: \(eventName) with accession number: \(accessionNumber)")
        if osirix.state == .on {
            log(msg:"Launching Osirix")
            if eventName == "open-imaging-study" {
                launchOsirix(command: "DisplayStudy", parameter: "accessionNumber", value: accessionNumber)
            }
            else {
                launchOsirix(command: "CloseAllWindows", parameter: "", value: "")
            }
            
        }
    }
    
    func launchOsirix( command:String, parameter: String,  value: String) {
        let osirixURL = URL(string: "http://localhost:8080/")!
        let session = URLSession.shared
        var request = URLRequest(url: osirixURL)
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString  = """
<?xml version="1.0"?>
<methodCall>
<methodName>\(command)</methodName>
<params><param><value><struct><member>
<name>\(parameter)</name>
<value>
<string>\(value)</string>
</value>
</member></struct></value></param></params>
</methodCall>
"""
        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler:
        {
            data, response, error in guard let data = data, error == nil else
            {
                print("error = \(String(describing: error))")
                return
            }
            print("response = \(String(describing: response))")
            print("data = \(String(describing: data))")
        }
        )
        task.resume()
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
        
        if (autoSubscribe.state == .on)   { defaults.set(true, forKey: "auto-subscribe") }
          else { defaults.set(false, forKey: "auto-subscribe") }
        if (osirix.state == .on)   { defaults.set(true, forKey: "osirix") }
          else { defaults.set(false, forKey: "osirix") }
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

