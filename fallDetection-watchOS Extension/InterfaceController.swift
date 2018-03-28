//
//  InterfaceController.swift
//  fallDetection-watchOS Extension
//
//  Created by Rahul Racha on 2/21/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import CoreLocation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //
    }
    

    @IBOutlet var altimeterSwitch: WKInterfaceSwitch!
    @IBOutlet var altLabel: WKInterfaceLabel!
    @IBOutlet var stopBtn: WKInterfaceButton!
    
    var altimeter = CMAltimeter()
    var locationManager:CLLocationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    var wcSession: WCSession!
    var player: WKAudioFilePlayer!
    var statusObserver: NSKeyValueObservation?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        //self.stopBtn.setHidden(true)
        self.wcSession = WCSession.default
        self.wcSession.delegate = self
        wcSession.activate()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        locationManager.requestWhenInUseAuthorization()
        self.locationManager.delegate = self as? CLLocationManagerDelegate
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        if (self.locationManager != nil) {
            self.locationManager.stopUpdatingLocation()
        }
        if (self.motionManager != nil) {
            self.motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func performAction(actionStyle: WKAlertActionStyle) {
        switch actionStyle {
        case .default:
            print("OK")
        case .cancel:
            print("Cancel")
        case .destructive:
            print("Destructive")
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        var alt = newLocation.altitude
        print("\(alt)")
        self.altLabel.setText(String(format: "%0.2f", alt))
    }
    
    func startAltimeter() {
        
        print("Started relative altitude updates.")
        
        // Check if altimeter feature is available
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            
            //self.activityIndicator.startAnimating()
            
            // Start altimeter updates, add it to the main queue
            self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
                
                if (error != nil) {
                    
                    // If there's an error, stop updating and alert the user
                    
                    self.altimeterSwitch.setOn(false)
                    self.stopAltimeter()
                    print("Error in altitude Data")
                    let okAction = WKAlertAction(title: "OK",
                                                 style: WKAlertActionStyle.default) { () -> Void in
                                                    self.performAction(actionStyle: WKAlertActionStyle.default)
                    }
                    self.presentAlert(withTitle: "Alert",
                                      message: error!.localizedDescription,
                                      preferredStyle: WKAlertControllerStyle.alert,
                                      actions: [okAction])
                    
                } else {
                    
                    let altitude = altitudeData!.relativeAltitude.floatValue    // Relative altitude in meters
                    let pressure = altitudeData!.pressure.floatValue            // Pressure in kilopascals
                    
                    // Update labels, truncate float to two decimal points
                    let text = String(format: "%.02f", altitude)
                    self.altLabel.setText(text)
                    //self.pressureLabel.text = String(format: "%.02f", pressure)
                }
                
            })
            
        } else {
            print("Relative altitude not available")
            let okAction = WKAlertAction(title: "OK",
                                         style: WKAlertActionStyle.default) { () -> Void in
                                            self.performAction(actionStyle: WKAlertActionStyle.default)
            }
            presentAlert(withTitle: "Alert",message: "Relative altitude not available",
                         preferredStyle: WKAlertControllerStyle.alert,
                         actions: [okAction])
            
        }
        
    }
    
    func stopAltimeter() {
        
        // Reset labels
        self.altLabel.setText("-")
        //self.pressureLabel.text("-")
        
        self.altimeter.stopRelativeAltitudeUpdates() // Stop updates
        
        //self.activityIndicator.stopAnimating() // Hide indicator
        
        print("Stopped relative altitude updates.")
        
    }
    
    func  startDeviceMotion() {
        if (motionManager.isDeviceMotionAvailable) {
            self.motionManager.deviceMotionUpdateInterval = 5
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
                if (magnitude < 1.1 && magnitude > 5) {
                    print("oki : \(magnitude)")
                }
                print(magnitude)
            }
            
        }
    }
    
    func playSound() {
        let myBundle = Bundle.main
        if let audioURL = myBundle.url(forResource: "alert_sound", withExtension: "mp3") {
            //self.movie.setMovieURL(audioURL)
            let asset = WKAudioFileAsset(url: audioURL)
            let item = WKAudioFilePlayerItem(asset: asset)
            self.player = WKAudioFilePlayer(playerItem: item)
            self.player.play()
        }
    }
    
    func sendMessage(msg: String) {
        let msg = ["message": msg]
        self.wcSession.sendMessage(msg, replyHandler: nil, errorHandler: {
            error in
            print(error.localizedDescription)
        })
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let txt = message["message"] as! String
        self.altLabel.setText(txt)
        if (txt != "Normal" && txt != "Unknown") {
            self.stopBtn.setHidden(false)
            self.playSound()
        } else {
            self.stopBtn.setHidden(true)
            self.player.pause()
        }
    }
    
    @IBAction func stopSound() {
        self.stopBtn.setHidden(true)
        self.player.pause()
        self.altLabel.setText("Normal")
        self.sendMessage(msg: "stop")
    }
    
    
    
    
//    @IBAction func switchDidChange(_ value: Bool) {
//        if (value == true) {
//            self.startDeviceMotion()
////            if #available(watchOSApplicationExtension 3.0, *) {
////                self.locationManager.startUpdatingLocation()
////            } else {
////                // Fallback on earlier versions
////            }
//            //self.startAltimeter()
//        } else {
//            self.motionManager.stopDeviceMotionUpdates()
//            //self.locationManager.stopUpdatingLocation()
//            //self.stopAltimeter()
//        }
//
//    }

}
