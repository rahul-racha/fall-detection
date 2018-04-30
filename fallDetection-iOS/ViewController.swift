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
    @IBOutlet weak var activityTypeLabel: UILabel!
    @IBOutlet weak var stepsCountLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motionManager = CMMotionManager()
    let locationManager: CLLocationManager = CLLocationManager()
    let altimeter = CMAltimeter()
    var altValue: Double = 0
    var magValue: Double = 0
    var gravityVal: Double = 0
    var userVal: Double = 0
    var bombSoundEffect: AVAudioPlayer?
    var flag: Bool?
    var fixAlt: Double = 0.0
    var isFall = false
    var accSign: Double = 0.0
    var wcSession: WCSession?
    var timer: Timer?
    var queue = Queue<Double>()
    var threshCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityTypeLabel.text = "unknown activity"
        self.stepsCountLabel.text = "unknown steps"
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
        self.wcSession!.delegate = self
        wcSession!.activate()
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
    
    func findAngle(v1: Vector3, v2: Vector3) -> Double {
        let dotPdt = v1.dot(v2)
        let cosTheta = dotPdt/(v1.length*v2.length)
        let angle = acos(cosTheta)
        return Double(angle)
    }
    
    func sendMessage(msg: String) {
        let msg = ["message": msg]
        self.wcSession?.sendMessage(msg, replyHandler: nil, errorHandler: {
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
        if (self.timer == nil) {
            self.timer = Timer.scheduledTimer(timeInterval: 1/65, target: self, selector: #selector(ViewController.trackSensorReadings), userInfo: nil, repeats: true)
        }
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
            var ax: Double = 0
            var ay: Double = 0
            var az: Double = 0
            var gx: Double = 0
            var gy: Double = 0
            var gz: Double = 0
            
            if let c = data?.gravity.x {
                gx = c
            }
            if let c = data?.gravity.y {
                gy = c
            }
            if let c = data?.gravity.z {
                gz = c
            }
            
            if let c = data?.userAcceleration.x {
                ax = c
            }
            if let c = data?.userAcceleration.y {
                ay = c
            }
            if let c = data?.userAcceleration.z {
                az = c
            }
            self?.updateAccData(ax: ax, ay: ay, az: az, gx: gx, gy: gy, gz: gz)
        }
    }
    
    func updateAccData(ax: Double, ay: Double, az: Double, gx: Double, gy: Double, gz: Double) {

        let gravityVector = Vector3(x: Scalar(CGFloat(gx)),
                                    y: Scalar(CGFloat(gy)),
                                    z: Scalar(CGFloat(gz)))
        
//        let angle = gravityVector
//        var sq_sum = pow(gx,2)+pow(gy,2)+pow(gz,2)
        self.gravityVal = Double(gravityVector.length)//sqrt(sq_sum)
        
        let userAccelerationVector = Vector3(x: Scalar(CGFloat(ax)),
                                             y: Scalar(CGFloat(ay)),
                                             z: Scalar(CGFloat(az)))
        
//        sq_sum = pow(ax,2)+pow(ay,2)+pow(az,2)
        self.userVal = Double(userAccelerationVector.length)//sqrt(sq_sum)
        
        var angle = self.findAngle(v1: gravityVector, v2: userAccelerationVector)
        
        let zVector = gravityVector * userAccelerationVector
        let zAcceleration = zVector.length
        print("*****")
        print("gravity vector: \(gravityVector)")
        print("user vector: \(userAccelerationVector)")
        print("zVector: \(zVector)")
        print("zAcceleration:  \(zAcceleration)")
        print("user acceleration: \(self.userVal)")
        print("g acceleration: \(self.gravityVal)")
        print("Angle: \(angle)")
        print("*****")
        self.magValue = self.userVal//Double(zAcceleration)
        self.accSign = sign(Double(zVector.x * zVector.y * zVector.z))
        //print(self?.accSign)
        self.magLabel.text = String(self.magValue)
        
        //handle queue
        if (self.queue.count >= 120) {
            let t = self.queue.dequeue()
            if (t! > 0.5 && t! < 1.2) {
                self.threshCount -= 1
            }
        } else {
            self.queue.enqueue(self.magValue)
            if (self.magValue > 0.5 && self.magValue < 1.2) {
                self.threshCount += 1
            }
        }
    }
    
    func  startDeviceMotion() {
        if (self.motionManager.isDeviceMotionAvailable && CMAltimeter.isRelativeAltitudeAvailable()) {
            self.sendMessage(msg: "Normal")
            self.activityIndicator.startAnimating()
            self.startAccelerometer()
            self.startAltimeter()
            self.startUpdating()
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
                    self.altValue = altitudeData!.relativeAltitude.doubleValue    // Relative altitude in meters
                    self.altLabel.text = String(self.altValue)
                    //self.updateAltitude()
                }
            })
    }
    
    func updateAltitude() {
        print("*****altitude**** \(self.altValue)")
        self.altLabel.text = String(self.altValue)
        
        if (self.magValue > 0.6 && self.magValue < 1.1 /*&& self.altValue < -0.2 && self.accSign < 0*/) {
            //print("oki : \(self.magValue)")
            if (self.flag == true) {
                self.view.backgroundColor = UIColor.yellow
                self.fixAlt = self.altValue - 0.2
                let mainQueue = DispatchQueue.main
                var deadline = DispatchTime.now() + .seconds(10)
                mainQueue.asyncAfter(deadline: deadline) {
                    deadline = DispatchTime.now() + .seconds(5)
                    if (self.altValue <= -0.4/*self.fixAlt + 0.15*/) {
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
    
    func startTrackingActivityType() {
        activityManager.startActivityUpdates(to: OperationQueue.main) {
            [weak self] (activity: CMMotionActivity?) in
            
            guard let activity = activity else { return }
            DispatchQueue.main.async {
                if activity.walking {
                    self?.activityTypeLabel.text = "Walking"
                } else if activity.stationary {
                    self?.activityTypeLabel.text = "Stationary"
                } else if activity.running {
                    self?.activityTypeLabel.text = "Running"
                } else if activity.automotive {
                    self?.activityTypeLabel.text = "Automotive"
                }
            }
        }
    }
    
    func startCountingSteps() {
        pedometer.startUpdates(from: Date()) {
            [weak self] pedometerData, error in
            guard let pedometerData = pedometerData, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.stepsCountLabel.text = pedometerData.numberOfSteps.stringValue
            }
        }
    }
    
    func startUpdating() {
        if CMMotionActivityManager.isActivityAvailable() {
            self.startTrackingActivityType()
        }
        
        if CMPedometer.isStepCountingAvailable() {
            self.startCountingSteps()
        }
    }
    
    @objc func trackSensorReadings() {
        print("$$$$$$$ THRESH: \(self.threshCount)")
        if (self.threshCount >= 6) {
        //if (self.magValue > 0.4 && self.magValue < 1.1 /*&& self.altValue < -0.2 && self.accSign < 0*/) {
            if (self.flag == true) {
                self.view.backgroundColor = UIColor.yellow
                //self.fixAlt = self.altValue - 0.2
                let mainQueue = DispatchQueue.main
                var deadline = DispatchTime.now() + .seconds(10)
                mainQueue.asyncAfter(deadline: deadline) {
                    deadline = DispatchTime.now() + .seconds(5)
                    /*self.fixAlt + 0.15*/
                    if (self.altValue <= -0.4 && self.activityTypeLabel.text == "Stationary") {
                        //dismiss alert view
                        let alert = self.handleAlertAction(title: "Fall Detected", message: "Do you want to alert your friends?", actionTitle1: "Yes", actionTitle2: "No")
                        mainQueue.asyncAfter(deadline: deadline) {
                            //if (alert.presentedViewController != nil) {
                            alert.dismiss(animated: true, completion: nil)
                            self.isFall = true
                            //}
                            if (self.isFall == true && self.flag == true) {
                                self.sendMessage(msg: "Patient needs help!")
                                self.timer?.invalidate()
                                self.timer = nil
                                self.handleFall()
                            }
                        }
                    } else {
                        self.view.backgroundColor = UIColor.white
                    }
                }
            }
        }
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
            if (self.timer == nil) {
                self.timer = Timer.scheduledTimer(timeInterval: 1/35, target: self, selector: #selector(ViewController.trackSensorReadings), userInfo: nil, repeats: true)
            }
            self.view.backgroundColor = UIColor.white
            self.locationManager.startUpdatingLocation()
            self.startDeviceMotion()
            
        } else {
            self.stopDeviceMotion()
            self.activityManager.stopActivityUpdates()
            self.pedometer.stopUpdates()
            self.timer?.invalidate()
            self.timer = nil
            self.locationManager.stopUpdatingLocation()
            self.view.backgroundColor = UIColor.white
        }
        
    }


}

