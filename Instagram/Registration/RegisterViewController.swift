//
//  RegisterViewController.swift
//  Instagram
//
//  Created by user143023 on 9/27/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
        
    var isOkToRegister: (String, String, String, String)? {
        guard  let email =  emailTextField.text,
               let password = passwordTextField.text,
        let firstname = firstnameTextField.text,
        let lastname = lastnameTextField.text,
        !email.isEmpty, !password.isEmpty,
        !firstname.isEmpty, !lastname.isEmpty
        else {
            return nil
        }
        return (email, password, firstname, lastname)
    }
    
    @IBAction func didTapRegister(_ sender: UIButton) {
        guard let (email, password, firstname, lastname) = isOkToRegister else{
            let alert = UIAlertController(title: "Registration Error", message: "Fill up all the fields.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        var data = RegisterData()
        data.email = email
        data.password = password
        data.firstName = firstname
        data.lastName = lastname
        
        let auth = Auth.auth()
        
        auth.createUser(withEmail: email, password: password, completion: { (result, error) in
            if error == nil {
                if let result = result {
                    let id = result.user.uid
                    //let id = auth.currentUser!.uid
                    let userInfo = ["firstname": data.firstName, "lastname": data.lastName, "id": id, "email": data.email, "post_count": 0, "following_count": 0, "follower_count": 0] as [String : AnyObject]
                    let ref = Database.database().reference()
                    let path = "users/\(id)"
                    ref.child(path).setValue(userInfo)
                    
                    let alert = UIAlertController(title: "Registration Success", message: "success", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Registration Error 1", message: "error ONE", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: "Registration Error 2", message: "error TWO", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            })
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func registerButtonClicked(_ sender: Any) {
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
