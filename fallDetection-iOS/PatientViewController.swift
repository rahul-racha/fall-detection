//
//  PatientViewController.swift
//  fallDetection-iOS
//
//  Created by Rahul Racha on 2/26/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import WatchConnectivity

class PatientViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WCSessionDelegate {
    
    @IBOutlet weak var patientTableView: UITableView!
    @IBOutlet weak var btnStop: UIButton!
    
    var bombSoundEffect: AVAudioPlayer?
    var alertCell = [PatientTableTableViewCell]()
    var flag: Bool?
    var wcSession: WCSession!
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.patientTableView.tableFooterView = UIView(frame: .zero)
        NotificationCenter.default.addObserver(self, selector: #selector(PatientViewController.catchStatusNotification(notification:)), name: .statusNotificationKey, object: nil)
        let parameters: Parameters = [:]
        Alamofire.request(Manager.getPatients,method: .post,parameters: parameters, encoding: URLEncoding.default).validate(statusCode: 200..<300).validate(contentType: ["application/json"])
            .responseData { response in
                if let data = response.data {
                    do {
                        Manager.patientDetails = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [Dictionary<String,Any>]
                        DispatchQueue.main.async(execute: {
                            self.patientTableView.reloadData()
                        })
                    }
                    catch {
                        self.displayAlertMessage(title:"Error", message: "error serializing JSON: \(error)")
                    }
                }
        }
        
        self.wcSession = WCSession.default
        self.wcSession.delegate = self
        wcSession.activate()
    }

    func displayAlertMessage(title: String, message: String) {
        let alertMsg = UIAlertController(title:"Alert", message: message,
                                         preferredStyle:UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil )
        alertMsg.addAction(confirmAction)
        present(alertMsg, animated:true, completion: nil)
    }
    
    func updateTableCell(idx: Int) {
        let indexPath = IndexPath(row: idx, section: 0)
        let cell = self.patientTableView.cellForRow(at: indexPath) as! PatientTableTableViewCell
        self.alertCell.append(cell)
        cell.backgroundColor = UIColor.red
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if Manager.patientDetails != nil {
            return Manager.patientDetails!.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "patient_cell", for: indexPath) as! PatientTableTableViewCell
        cell.name.text = Manager.patientDetails![indexPath.row]["username"] as! String
        return cell
    }
    
    @objc func catchStatusNotification(notification: Notification) {
        let patient = notification.userInfo as? [String: Any]
        for i in 0..<Manager.patientDetails!.count {
            if (Manager.patientDetails![i]["id"] as! String == patient!["id"] as! String) {
                //Manager.patientDetails[i]["status"] = patient["status"] as! String
                self.updateTableCell(idx: i)
                self.handleFall()
                break
            }
        }
        self.handleFall()
    }
    
    func sendMessage(msg: String) {
        let msg = ["message": msg]
        self.wcSession.sendMessage(msg, replyHandler: nil, errorHandler: {
            error in
            print(error.localizedDescription)
        })
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if (self.flag == false && message["message"] as! String == "stop") {
            DispatchQueue.main.async {
                self.bombSoundEffect?.stop()
                self.flag = true
                self.btnStop.isHidden = true
                for cell in self.alertCell {
                    cell.backgroundColor = UIColor.white
                }
            }
        }
    }
    
    func handleFall() {
        self.sendMessage(msg: "Patient needs help!")
        self.btnStop.isHidden = false
        self.flag = false
        //self.view.backgroundColor = UIColor.red
        let path = Bundle.main.path(forResource: "alert_sound", ofType:"mp3")
        let url = URL(fileURLWithPath: path!)
        
        do {
            self.bombSoundEffect = try AVAudioPlayer(contentsOf: url)
            self.bombSoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
    }
    
    
    @IBAction func stopAction(_ sender: UIButton) {
        self.bombSoundEffect?.stop()
        self.flag = true
        self.btnStop.isHidden = true
        for cell in self.alertCell {
            cell.backgroundColor = UIColor.white
        }
        self.sendMessage(msg: "Normal")
}

}

extension Notification.Name {
    static let statusNotificationKey = Notification.Name("com.fall.status")
}
