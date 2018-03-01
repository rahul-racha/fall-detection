//
//  LoginViewController.swift
//  fallDetection-iOS
//
//  Created by Rahul Racha on 2/26/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import UIKit
import Alamofire

class LoginViewController: UIViewController {
    
    @IBOutlet weak var _username: UITextField!
    @IBOutlet weak var _password: UITextField!
    @IBOutlet weak var rememberCredentials: UISwitch!
    @IBOutlet weak var btnLogin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let window = self.view.window?.frame {
            // We're not just minusing the kb height from the view height because
            // the view could already have been resized for the keyboard before
            self.view.frame = CGRect(x: self.view.frame.origin.x,
                                     y: self.view.frame.origin.y,
                                     width: self.view.frame.width,
                                     height: window.origin.y + window.height - keyboardSize.height)
        } else {
            debugPrint("Window frame is nil.")
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let viewHeight = self.view.frame.height
            self.view.frame = CGRect(x: self.view.frame.origin.x,
                                     y: self.view.frame.origin.y,
                                     width: self.view.frame.width,
                                     height: viewHeight + keyboardSize.height)
        } else {
            debugPrint("Window frame is nil.")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self);
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
   
    func displayAlertMessage(title: String, message: String) {
        let alertMsg = UIAlertController(title:"Alert", message: message,
                                         preferredStyle:UIAlertControllerStyle.alert);
        
        let confirmAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil );
        alertMsg.addAction(confirmAction)
        present(alertMsg, animated:true, completion: nil)
    }
   
    @IBAction func login(_ sender: Any) {
    var username = _username?.text
        var password = _password?.text
        if (username?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty)! || (password?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty)! {
            
            displayAlertMessage(title: "Validation", message: "All fields are required")
            return
        }
        username = username?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        password = password?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.verifyLogin(username: username!, password: password!)
    }
    
    func verifyLogin(username: String, password: String) {
        let parameters: Parameters = ["username":username, "password": password, "device_id": Manager.deviceId == nil ? "abc" : Manager.deviceId!, "device_type" : "iOS"]
        Alamofire.request(Manager.loginService, method: .post, parameters: parameters, encoding: URLEncoding.default).validate(statusCode: 200..<300)/*.validate(contentType: ["application/json"])*/
            .responseData { response in
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print(data)
                    if let dict = self.convertToDictionary(text: utf8Text) {
                        if (dict["user_details"] != nil) {
                            Manager.userData = dict["user_details"] as! [String: String]
                            print(Manager.userData)
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            if (Manager.userData!["role_name"] == "patient") {
                    let destinationController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                    UIApplication.shared.keyWindow?.rootViewController = destinationController
                    self.present(destinationController, animated: true, completion: nil)
                            } else {
                                let destinationController = storyboard.instantiateViewController(withIdentifier: "PatientViewController") as! PatientViewController
                                UIApplication.shared.keyWindow?.rootViewController = destinationController
                                self.present(destinationController, animated: true, completion: nil)
                            }
                        }
                    } else {
                        if (utf8Text.range(of:"Exception") != nil) {
                            self.displayAlertMessage(title: "Alert", message: utf8Text)
                        }
                    }
            } else {
                self.displayAlertMessage(title: "Validation", message: "invalid response from server")
                self._username?.text = nil
                self._password?.text = nil
            }
        }
                
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
