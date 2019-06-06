//
//  ErrorHandler.swift
//  Instagram
//
//  Created by user143023 on 9/29/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase

struct service {
    
    static let dbRef = Database.database().reference()
    
    static func errorAlert(controller: UIViewController, title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        controller.present(alert, animated: true, completion: nil)
    }
    
    static func followAndUnfollow (currentUid: String, targetUid: String, willFollow: Bool, countChange: Int, vc: UIViewController, cell: UserCollectionViewCell? = nil, userProfileVC: UserProfileViewController? = nil) {
        guard currentUid != targetUid else {
            errorAlert(controller: vc, title: "Error", message: "Cannot follow yourself")
            return
        }
        
        let followingPath = "user-following/\(currentUid)/following"
        let followerPath = "user-follower/\(targetUid)/follower"
        
        //ErrorHandler.errorAlert(controller: self, title: String(index), message: "Did tap follow, "+String(followingId))
        
        dbRef.child(followingPath).child(targetUid).observeSingleEvent(of: .value, with: { snapshot in
            let isFollowing =  snapshot.value as? Bool
            guard isFollowing != willFollow else {
                service.errorAlert(controller: vc, title: "Error", message: "Illegal operation! You have already followed or unfollowed this user, please refresh the page.")
                return
            }
            
            let followingData: [String: Bool] = [targetUid: willFollow]
            let followerData: [String: Bool] = [currentUid: willFollow]
            
            dbRef.child(followingPath).updateChildValues(followingData)
            dbRef.child(followerPath).updateChildValues(followerData)
            
            // Update the following count value in "user" table
            let userRef = dbRef.child("users").child(currentUid)
            userRef.observeSingleEvent(of: .value, with: { snapshot in
                let value = snapshot.value as? NSDictionary
                var followingCount = value?["following_count"] as! Int
                followingCount += countChange
                let newCount: [String:Int] = ["following_count":followingCount]
                userRef.updateChildValues(newCount)
            })
            // Update the follower count value in "user" table
            let targetRef = dbRef.child("users").child(targetUid)
            targetRef.observeSingleEvent(of: .value, with: { snapshot in
                let value = snapshot.value as? NSDictionary
                var followerCount = value?["follower_count"] as! Int
                followerCount += countChange
                let newCount: [String:Int] = ["follower_count":followerCount]
                targetRef.updateChildValues(newCount)
            })
            // Update the user-activity table for following a user
            
            updateActivity(actorId: currentUid, targetId: targetUid, isActive: willFollow, type: "follow")
            
            if let cell = cell {
                if(willFollow) {
                    cell.followButton.setTitle("Unfollow", for: UIControlState.normal)
                } else {
                    cell.followButton.setTitle("Follow", for: UIControlState.normal)
                }
            }
            if let vc = userProfileVC {
                if(willFollow) {
                    vc.followThisUserButton.setTitle("Unfollow", for: UIControlState.normal)
                } else {
                    vc.followThisUserButton.setTitle("Follow", for: UIControlState.normal)
                }
            }
        })
        

        
        /*

        let activityPath = "user-activity/\(currentUid)/has-followed/\(targetUid)"
        if (isfollowing) {
            let data = ["isActive" : true, "timestamp": ServerValue.timestamp()] as [String: AnyObject]
            dbRef.child(activityPath).updateChildValues(data)
        } else {
            let data = ["isActive": false] as [String: Bool]
            dbRef.child(activityPath).updateChildValues(data)
        }
        */
    }
    
    static func updateActivity(actorId: String, targetId: String, isActive: Bool, type: String) {
        
        var newActivity = true
        dbRef.child("activities").observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let aid = ((child as! DataSnapshot).value as? NSDictionary)?["actorId"] as! String
                let tid = ((child as! DataSnapshot).value as? NSDictionary)?["targetId"] as! String
                if (actorId == aid && targetId == tid) {
                    //errorAlert(controller: vc, title: "1", message: "success")
                    let data = ["timestamp" : ServerValue.timestamp()]
                    (child as! DataSnapshot).ref.updateChildValues(data)
                    
                    let userActData = [(child as! DataSnapshot).key : isActive]
                    dbRef.child("user-activity/\(actorId)").updateChildValues(userActData)
                    newActivity = false
                }
            }
            
            if (newActivity) {
                let key = dbRef.child("activities").childByAutoId().key
                let path = "activities/\(key!)"
                let data = [
                    "id": key!,
                    "actorId": actorId,
                    "targetId": targetId,
                    "timestamp": ServerValue.timestamp(),
                    "type": type
                    ] as [String: AnyObject]
                dbRef.child(path).setValue(data)
                let userActData = [key : isActive]
                dbRef.child("user-activity/\(actorId)").updateChildValues(userActData)
                
            }
        })
    }
}
