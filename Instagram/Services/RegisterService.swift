//
//  RegisterService.swift
//  Instagram
//
//  Created by user143023 on 9/27/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

struct RegisterData {
    var email: String = ""
    var password: String = ""
    var firstName: String = ""
    var lastName: String = ""
}

struct RegisterResult {
    var user: User?
    var error: RegisterError?
}

enum RegisterError: Error {
    case authenticatedUserNotFound(message: String)
    case invalidRegisterCredentials(message: String)
    
    var message: String {
        switch self {
        case
             .authenticatedUserNotFound(let message),
             .invalidRegisterCredentials(let message):
            return message
        }
    }
}

struct RegisterService {
    

func register(data: RegisterData, callback:((RegisterResult) -> Void)?) {
    var result = RegisterResult()
    let auth = Auth.auth()
    
    auth.createUser(withEmail: data.email, password: data.password, completion: { (user, error) in
        guard error == nil else {
            result.error = .invalidRegisterCredentials(message: "Invalid registration credentials")
            callback?(result)
            return
        }
        
        guard let authUser = user else {
            result.error = .authenticatedUserNotFound(message: "Authnticated user not found")
            callback?(result)
            return
        }
        
        let id = authUser.user.uid
        //let id = auth.currentUser!.uid
        let userInfo = ["firstname": data.firstName, "lastname": data.lastName, "id": id, "email": data.email]
        let ref = Database.database().reference()
        let path = "users/\(id)"
        ref.child(path).setValue(userInfo)
        
        /*
        var u = User()
        u.id = id
        u.email = data.email
        u.firstName = data.firstName
        u.lastName = data.lastName
        
        result.user = u
        callback?(result)
 */
        
    })
}
}
