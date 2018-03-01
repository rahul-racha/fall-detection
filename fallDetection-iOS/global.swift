//
//  global.swift
//  fallDetection-iOS
//
//  Created by Rahul Racha on 2/26/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import Foundation

struct Manager {
    static var deviceId: String?
    static var userData: [String: String]?
    static var patientDetails: [Dictionary<String,Any>]?
    static var loginService = "http://qav2.cs.odu.edu/fall_detection/login.php"
    static var updateStatus = "http://qav2.cs.odu.edu/fall_detection/updatePatientStatus.php"
    static var getPatients = "http://qav2.cs.odu.edu/fall_detection/getPatients.php"
}
