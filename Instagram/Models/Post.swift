//
//  Post.swift
//  Instagram
//
//  Created by user143023 on 10/2/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Post {
    
    let key: String
    let userId: String
    let likeCount: Int
    let commentCount: Int
    let url: String!
    let time: TimeInterval
    let message: String?
    let location: String?
    
    let postRef: DatabaseReference?
    
    
    init(snapshot:DataSnapshot) {
        key = snapshot.key
        postRef = snapshot.ref
        
        let snapshotValue = snapshot.value as? NSDictionary
        
        if let photoUrl = snapshotValue?["url"] as? String {
            url = photoUrl
        } else {
            url = ""
        }
        
        if let uid = snapshotValue?["uid"] as? String {
            userId = uid
        } else {
            userId = ""
        }
        
        if let lcount = snapshotValue?["likes_count"] as? Int {
            likeCount = lcount
        } else {
            likeCount = 0
        }
        
        if let ccount = snapshotValue?["comments_count"] as? Int {
            commentCount = ccount
        } else {
            commentCount = 0
        }
        
        if let t = snapshotValue?["timestamp"] as? TimeInterval {
            time = t
        } else {
            time = 0
        }
        
        if let m = snapshotValue?["message"] as? String {
            message = m
        } else {
            message = nil
        }
        
        if let l = snapshotValue?["location"] as? String {
            location = l
        } else {
            location = nil
        }
        
    }
}
