//
//  ViewController.swift
//  fallDetection-iOS
//
//  Created by Rahul Racha on 2/21/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import Alamofire
import WatchConnectivity
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, CLLocationManagerDelegate, WCSessionDelegate {
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    

    @IBOutlet weak var magLabel: UILabel!
    @IBOutlet weak var altLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var switchManager: UISwitch!
    
    let motionManager = CMMotionManager()
    let locationManager: CLLocationManager = CLLocationManager()
    let altimeter = CMAltimeter()
    var altValue: Double = 0
    var magValue: Double = 0
    var gravityVal: Double = 0
    var bombSoundEffect: AVAudioPlayer?
    var flag: Bool?
    var fixAlt: Double = 0.0
    var isFall = false
    var accSign: Double = 0.0
    var wcSession: WCSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.magLabel.text = "0"
        self.altLabel.text = "0"
        self.flag = true
        self.activityIndicator.stopAnimating()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.distanceFilter = 5000
        self.wcSession = WCSession.default
        self.wcSession.delegate = self
        wcSession.activate()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//    var presentedItemURL: NSURL? {
//        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.fallDetection")
//        let fileURL = groupURL?.appendingPathComponent("notes.bin")
//        return fileURL! as NSURL
//    }

    func displayAlertMessage(title: String, message: String) {
        let alertMsg = UIAlertController(title:"Alert", message: message,
                                         preferredStyle:UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil )
        alertMsg.addAction(confirmAction)
        present(alertMsg, animated:true, completion: nil)
    }
    
    func handleAlertAction(title: String, message: String, actionTitle1: String, actionTitle2: String) -> UIAlertController {
        let alertMsg = UIAlertController(title:title, message: message,
                                         preferredStyle:UIAlertControllerStyle.alert);
        self.isFall = true
//        let confirmAction2 = UIAlertAction(title: actionTitle2, style: UIAlertActionStyle.default, handler:
//        { (action) -> Void in
//            self.dismiss(animated: true, completion: nil)
//            self.isFall = false
//        })
        let confirmAction2 = UIAlertAction(title: actionTitle2, style: UIAlertActionStyle.default, handler:
        { (action) -> Void in
            self.dismiss(animated: true, completion: nil)
            self.isFall = false
            self.view.backgroundColor = UIColor.white
        })
        //alertMsg.addAction(confirmAction1)
        alertMsg.addAction(confirmAction2)
        present(alertMsg, animated:true, completion: nil)
        return alertMsg
    }
    
    func handleFall() {
        self.sendUpdate()
        self.btnStop.isHidden = false
        self.flag = false
        self.view.backgroundColor = UIColor.red
        let path = Bundle.main.path(forResource: "alert_sound", ofType:"mp3")
        let url = URL(fileURLWithPath: path!)
        
        do {
            self.bombSoundEffect = try AVAudioPlayer(contentsOf: url)
            self.bombSoundEffect?.numberOfLoops = -1
            self.bombSoundEffect?.play()
        } catch {
            self.displayAlertMessage(title: "Audio", message: "couldn't load file :(")
        }
    }
    
    func sendMessage(msg: String) {
        let msg = ["message": msg]
        self.wcSession.sendMessage(msg, replyHandler: nil, errorHandler: {
            error in
            print(error.localizedDescription)
        })
    }
    
    @IBAction func stopAction(_ sender: UIButton) {
        self.bombSoundEffect?.stop()
        self.flag = true
        self.btnStop.isHidden = true
        self.view.backgroundColor = UIColor.white
        self.sendMessage(msg: "Normal")
    }
    
    func sendUpdate() {
        let parameters: Parameters = ["id":Manager.userData!["id"] as! String, "status": "fall"]
        Alamofire.request(Manager.updateStatus, method: .post, parameters: parameters, encoding: URLEncoding.default).validate(statusCode: 200..<300)/*.validate(contentType: ["application/json"])*/
            .responseData { response in
        }
    }
    
    func startAccelerometer() {
        self.motionManager.deviceMotionUpdateInterval = 1/30
        self.motionManager.showsDeviceMovementDisplay = true
        self.motionManager.startDeviceMotionUpdates()
        self.motionManager.startDeviceMotionUpdates(to: .main) {
            [weak self] (data: CMDeviceMotion?, error: Error?) in
            var accX: Double = 0
            var accY: Double = 0
            var accZ: Double = 0
            
            if let c = data?.gravity.x {
                accX = c
            }
            if let c = data?.gravity.y {
                accY = c
            }
            if let c = data?.gravity.z {
                accZ = c
            }
            let gravityVector = Vector3(x: Scalar(CGFloat(accX)),
                                        y: Scalar(CGFloat(accY)),
                                        z: Scalar(CGFloat(accZ)))
            
            var sq_sum = pow(accX,2)+pow(accY,2)+pow(accZ,2)
            var magnitude = sqrt(sq_sum)
            self?.gravityVal = magnitude
            
            if let c = data?.userAcceleration.x {
                accX = c
            }
            if let c = data?.userAcceleration.y {
                accY = c
            }
            if let c = data?.userAcceleration.z {
                accZ = c
            }
            let userAccelerationVector = Vector3(x: Scalar(CGFloat(accX)),
                                                 y: Scalar(CGFloat(accY)),
                                                 z: Scalar(CGFloat(accZ)))
            
            sq_sum = pow(accX,2)+pow(accY,2)+pow(accZ,2)
            magnitude = sqrt(sq_sum)
//            if (magnitude < 1.1 && magnitude > 0.2 && self!.altValue > 0.5) {
//                print("oki : \(magnitude)")
//                if (self?.flag == true) {
//                    self?.handleFall()
//                }
//            }
            self?.magValue = magnitude
            //print(magnitude)
            
            let zVector = gravityVector * userAccelerationVector
            let zAcceleration = zVector.length
            print(zVector)
            print("*****")
            print(zAcceleration)
            self?.magValue = Double(zAcceleration)
            self?.accSign = Double(sign(zVector.z))//sign(Double(zVector.x * zVector.y * zVector.z))
            //print(self?.accSign)
            self?.magLabel.text = String(magnitude)
        }
    }
    
    func  startDeviceMotion() {
        if (self.motionManager.isDeviceMotionAvailable && CMAltimeter.isRelativeAltitudeAvailable()) {
            self.sendMessage(msg: "Normal")
            self.activityIndicator.startAnimating()
            self.startAccelerometer()
            self.startAltimeter()
        } else {
            self.displayAlertMessage(title: "Sensors", message: "Realtive altitude/Device Motion not available in device")
        }
    }
    
    func stopDeviceMotion() {
        self.motionManager.stopDeviceMotionUpdates()
        self.stopAltimeter()
        self.activityIndicator.stopAnimating()
    }
    
    
    func startAltimeter() {
        print("Started relative altitude updates.")
            // Start altimeter updates, add it to the main queue
            self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
                if (error != nil) {
                    self.switchManager.isOn = false
                    print("Error in altitude Data")
                   self.displayAlertMessage(title: "Error", message: "Error in altitude Data")
                    
                } else {
                    let altitude = altitudeData!.relativeAltitude.floatValue    // Relative altitude in meters
                    self.altValue = Double(altitude)
                    print("*****altitude**** \(self.altValue)")
                    self.altLabel.text = String(self.altValue)
                    
                    if (self.magValue < 1.1 && self.magValue >= 0.25 && self.altValue < -0.2 /*&& self.accSign < 0*/) {
                        //print("oki : \(self.magValue)")
                        if (self.flag == true) {
                            self.view.backgroundColor = UIColor.yellow
                            self.fixAlt = self.altValue - 0.2
                            let mainQueue = DispatchQueue.main
                            var deadline = DispatchTime.now() + .seconds(10)
                            mainQueue.asyncAfter(deadline: deadline) {
                                deadline = DispatchTime.now() + .seconds(5)
                                if (self.altValue <= self.fixAlt + 0.15) {
                                    //dismiss alert view
                                    let alert = self.handleAlertAction(title: "Fall Detected", message: "Do you want to alert your friends?", actionTitle1: "Yes", actionTitle2: "No")
                                    mainQueue.asyncAfter(deadline: deadline) {
                                        //if (alert.presentedViewController != nil) {
                                            alert.dismiss(animated: true, completion: nil)
                                            self.isFall = true
                                        //}
                                        if (self.isFall == true) {
                                            self.sendMessage(msg: "Patient needs help!")
                                            self.handleFall()
                                        }
                                    }
                                } else {
                                    self.view.backgroundColor = UIColor.white
                                }
                            }
                        }
                    }
                    //let pressure = altitudeData!.pressure.floatValue            // Pressure in kilopascals
                    
                    // Update labels, truncate float to two decimal points
                    //let text = String(format: "%.02f", altitude)
                    //self.altLabel.setText(text)
                    //self.pressureLabel.text = String(format: "%.02f", pressure)
                }
            })
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if (self.flag == false && message["message"] as! String == "stop") {
            DispatchQueue.main.async {
                self.bombSoundEffect?.stop()
                self.flag = true
                self.btnStop.isHidden = true
                self.view.backgroundColor = UIColor.white
            }
        }
    }
    
    func stopAltimeter() {
        //self.altLabel.setText("-")
        //self.pressureLabel.text("-")
        self.altimeter.stopRelativeAltitudeUpdates() // Stop updates
    }
    
    @IBAction func switchDidChange(_ sender: UISwitch) {
        if (sender.isOn == true) {
            self.view.backgroundColor = UIColor.white
            self.locationManager.startUpdatingLocation()
            self.startDeviceMotion()
            
        } else {
            self.stopDeviceMotion()
            self.locationManager.stopUpdatingLocation()
            self.view.backgroundColor = UIColor.white
        }
        
    }


}

