	//
//  Profile.swift
//  Instagram
//
//  Created by user143023 on 9/27/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import Firebase

struct Profile {
    
    var userId: String
    var postsCount: Int
    var followersCount: Int
    var followingCount: Int
    
    init() {
        userId = ""
        postsCount = 0
        followersCount = 0
        followingCount = 0
    }
    
}
