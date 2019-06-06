//
//  Comment.swift
//  Instagram
//
//  Created by user143023 on 10/9/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Comment {
    
    let key: String
    let userId: String
    let postId: String
    let message: String
    let time: TimeInterval
    
    let commentRef: DatabaseReference?
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        commentRef = snapshot.ref
        
        let value = snapshot.value as? NSDictionary
        
        if let uid = value?["uid"] as? String {
            userId = uid
        } else {
            userId = ""
        }
        
        if let pid = value?["pid"] as? String {
            postId = pid
        } else {
            postId = ""
        }
        
        if let msg = value?["message"] as? String {
            message = msg
        } else {
            message = ""
        }
        
        if let t = value?["timestamp"] as? TimeInterval {
            time = t
        } else {
            time = 0
        }
    }
}
