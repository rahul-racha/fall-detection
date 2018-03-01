//
//  ViewController.swift
//  fallDetection-iOS
//
//  Created by Rahul Racha on 2/21/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import UIKit
import CoreMotion
import Alamofire
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var magLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var switchManager: UISwitch!
    
    let motionManager = CMMotionManager()
    let altimeter = CMAltimeter()
    var altValue: Double = 0
    var magValue: Double = 0
    var bombSoundEffect: AVAudioPlayer?
    var flag: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.magLabel.text = "0"
        self.flag = true
        self.activityIndicator.stopAnimating()
        // Do any additional setup after loading the view, typically from a nib.
    }

    func displayAlertMessage(title: String, message: String) {
        let alertMsg = UIAlertController(title:"Alert", message: message,
                                         preferredStyle:UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil )
        alertMsg.addAction(confirmAction)
        present(alertMsg, animated:true, completion: nil)
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
            self.bombSoundEffect?.play()
        } catch {
            self.displayAlertMessage(title: "Audio", message: "couldn't load file :(")
        }
    }
    
    @IBAction func stopAction(_ sender: UIButton) {
        self.bombSoundEffect?.stop()
        self.flag = true
        self.btnStop.isHidden = true
        self.view.backgroundColor = UIColor.white
    }
    
    func sendUpdate() {
        let parameters: Parameters = ["id":Manager.userData!["id"] as! String, "status": "fall"]
        Alamofire.request(Manager.updateStatus, method: .post, parameters: parameters, encoding: URLEncoding.default).validate(statusCode: 200..<300)/*.validate(contentType: ["application/json"])*/
            .responseData { response in
        }
    }
    
    func startAccelerometer() {
        self.motionManager.deviceMotionUpdateInterval = 1/60
        self.motionManager.showsDeviceMovementDisplay = true
        self.motionManager.startDeviceMotionUpdates()
        self.motionManager.startDeviceMotionUpdates(to: .main) {
            [weak self] (data: CMDeviceMotion?, error: Error?) in
            var accX: Double = 0
            var accY: Double = 0
            var accZ: Double = 0
            if let c = data?.userAcceleration.x {
                accX = c
            }
            if let c = data?.userAcceleration.y {
                accY = c
            }
            if let c = data?.userAcceleration.y {
                accZ = c
            }
            var sq_sum = pow(accX,2)+pow(accY,2)+pow(accZ,2)
            var magnitude = sqrt(sq_sum)
//            if (magnitude < 1.1 && magnitude > 0.2 && self!.altValue > 0.5) {
//                print("oki : \(magnitude)")
//                if (self?.flag == true) {
//                    self?.handleFall()
//                }
//            }
            self?.magValue = magnitude
            //print(magnitude)
            self?.magLabel.text = String(magnitude)
        }
    }
    
    func  startDeviceMotion() {
        if (self.motionManager.isDeviceMotionAvailable && CMAltimeter.isRelativeAltitudeAvailable()) {
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
                    if (self.magValue < 1.1 && self.magValue > 0.2 && self.altValue < 0) {
                        print("oki : \(self.magValue)")
                        if (self.flag == true) {
                            self.handleFall()
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
    
    func stopAltimeter() {
        //self.altLabel.setText("-")
        //self.pressureLabel.text("-")
        self.altimeter.stopRelativeAltitudeUpdates() // Stop updates
    }
    
    @IBAction func switchDidChange(_ sender: UISwitch) {
        if (sender.isOn == true) {
            self.startDeviceMotion()
            
        } else {
            self.stopDeviceMotion()
        }
        
    }


}

