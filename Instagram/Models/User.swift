//
//  User.swift
//  Instagram
//
//  Created by user143023 on 9/27/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct User {
    
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let avatarUrl: String?
    
    let itemRef: DatabaseReference?
    
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
    }
    
    
    init(snapshot: DataSnapshot) {
        id = snapshot.key
        itemRef = snapshot.ref
        
        let snapshotValue = snapshot.value as? NSDictionary
        
        if let firstname = snapshotValue?["firstname"] as? String {
            firstName = firstname
        } else {
            firstName = ""
        }
        
        if let lastname = snapshotValue?["lastname"]as? String {
            lastName = lastname
        } else {
            lastName = ""
        }

        if let email = snapshotValue?["email"]as? String {
            self.email = email
        } else {
            self.email = ""
        }
        
        if let url = snapshotValue?["avatar_url"]as? String {
            self.avatarUrl = url
        } else {
            avatarUrl = nil
        }
        
    }
    
}
