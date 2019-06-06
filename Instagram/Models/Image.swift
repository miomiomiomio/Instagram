//
//  CatInsta.swift
//  Instagram
//
//  Created by user143023 on 9/23/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Image{
    
    let key:String!
    let url:String!
    
    let itemRef: DatabaseReference?
    
    init(url:String, key:String) {
        self.key = key
        self.url = url
        self.itemRef = nil
    }
    
    init(snapshot:DataSnapshot) {
        key = snapshot.key
        itemRef = snapshot.ref
        
        let snapshotValue = snapshot.value as? NSDictionary
        
        if let imageUrl = snapshotValue?["url"] as? String {
            url = imageUrl
        } else {
            url = ""
        }
    }
}
