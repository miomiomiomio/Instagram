//
//  LoginViewController.swift
//  Instagram
//
//  Created by user143023 on 9/18/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginClickButton(_ sender: Any) {
        print("Login button clicked")
        
        if(usernameTextField.text != "" && passwordTextField.text != ""){
            Auth.auth().signIn(withEmail: usernameTextField.text!, password: passwordTextField.text!){
                (user, error) in
                
                if (user != nil) {
                    print("user authenticated")
                    self.presentingViewController?.dismiss(animated: true, completion: nil);
                } else {
                    print("there was an error")
                    self.errorLabel.isHidden = false
                }
            }
        } else {
            print("")
            self.errorLabel.isHidden = false
        }
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
