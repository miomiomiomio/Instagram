//
//  DiscoverViewController.swift
//  Instagram
//
//  Created by user143023 on 10/3/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class DiscoverViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var users = [User]()
    var searchUsers = [User]()
    var suggestedUsers : [String: Int] = [:]
    let myGroup = DispatchGroup()
    //let dbReff = Database.database().reference()
    
    @IBOutlet weak var userCollectionView: UICollectionView!
    @IBOutlet weak var searchUserTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    var searchUserCollection: UICollectionView!
    @IBOutlet weak var mutualFollowingNumberTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Auth.auth().addStateDidChangeListener { auth, user in
            
            if let user = user {
                self.suggestUser(userId: user.uid)

            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        self.suggestUser(userId: uid)
    }
    @IBAction func didTapSearchUser(_ sender: Any) {
        let dbRef = Database.database().reference()
        self.searchUsers = [User]()
        if let searchInput = searchUserTextField.text {
            dbRef.child("users").observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    let firstname = ((child as! DataSnapshot).value as? NSDictionary)?["firstname"] as! String
                    let lastname = ((child as! DataSnapshot).value as? NSDictionary)?["lastname"] as! String
                    let fullname = firstname + " " + lastname
                    if (firstname.caseInsensitiveCompare(searchInput) == ComparisonResult.orderedSame || lastname.caseInsensitiveCompare(searchInput) == ComparisonResult.orderedSame ||
                        searchInput.caseInsensitiveCompare(fullname) == ComparisonResult.orderedSame) {
                        //ErrorHandler.errorAlert(controller: self, title: "Success", message: "User found!")
                        let user = User(snapshot: child as! DataSnapshot)
                        self.searchUsers.append(user)
                    }
                }
                //self.searchUserCollection.reloadData()
                
                if (self.searchUsers.count > 0) {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier:"UserCollectionViewController") as? UserCollectionViewController
                    vc?.users = self.searchUsers
                    self.present(vc!, animated: true)
                }
            })
        }
    }
    
    func suggestUser (userId: String) {
        
        var mutualFollowingN = Int(mutualFollowingNumberTextField.text!)

        if mutualFollowingN == nil {
            mutualFollowingN = 0
        }
        let userPath = "user-following/\(userId)/following"
        let dbRef = Database.database().reference()
        
        self.myGroup.enter()
        dbRef.child(userPath).observeSingleEvent(of:.value, with: { snapshot in
            var currentUserFollowing = [String] ()
            for child in snapshot.children {
                let isFollowing = (child as! DataSnapshot).value as! Bool
                let key = (child as! DataSnapshot).key
                if (isFollowing) {
                    currentUserFollowing.append(key)
                }
            }
            
            self.myGroup.enter()
            dbRef.child("user-following").observeSingleEvent(of:.value, with: { snapshot in
                for child in snapshot.children {
                    //let ref = (child as! DataSnapshot).ref.child("following")
                    let snap = (child as! DataSnapshot).childSnapshot(forPath: "following")
                    let suggestUserId = (child as! DataSnapshot).key
                    
                    var otherUserFollowing = [String]()
                    var count = 0
                    
                    for child in snap.children {
                        let isFollowing = (child as! DataSnapshot).value as! Bool
                        let key = (child as! DataSnapshot).key
                        if (isFollowing) {
                            otherUserFollowing.append(key)
                        }
                    }
                    for cid in currentUserFollowing {
                        for tid in otherUserFollowing {
                            if cid == tid {
                                count += 1
                            }
                        }
                    }
                    
                    self.suggestedUsers[suggestUserId] = count
                }
                
                let userRef = Database.database().reference().child("users")
                self.myGroup.enter()
                userRef.observeSingleEvent(of:.value, with:  { snapshot in
                    
                    self.users = [User]()
                    
                    if(mutualFollowingN! <= 0) {
                        for child in snapshot.children {
                            let user = User(snapshot: child as! DataSnapshot)
                            self.users.append(user)
                        }
                    } else {
                        for child in snapshot.children {
                            let user = User(snapshot: child as! DataSnapshot)
                            
                            for (key, value) in self.suggestedUsers {
                                if (key == user.id) {
                                    if value >= mutualFollowingN! {
                                        self.users.append(user)
                                    }
                                }
                            }
                        }
                    }
                    self.myGroup.leave()
                })
                self.myGroup.leave()
            })
            self.myGroup.leave()
        })
        self.myGroup.notify(queue: .main) {
            self.userCollectionView.reloadData()
            print("Finished all requests,update discover")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == self.userCollectionView) {
            return users.count
        }
        if (collectionView == self.searchUserCollection) {
            return searchUsers.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! UserCollectionViewCell
        
        if(collectionView == self.userCollectionView) {
            let followingUser = users[indexPath.row]
            prepareCell(cell: cell, user: followingUser)
        }
        if(collectionView == self.searchUserCollection) {
            let searchUser = searchUsers[indexPath.row]
            prepareCell(cell: cell, user: searchUser)
        }
        
        cell.delegate = self
        return cell
    }
    
    func prepareCell(cell: UserCollectionViewCell, user:User) {
        if let userId = Auth.auth().currentUser?.uid {
            let path = "user-following/\(userId)/following"
            Database.database().reference().child(path).observeSingleEvent(of:.value, with: { snapshot in
                for child in snapshot.children {
                    let key = (child as! DataSnapshot).key
                    let isFollowing = (child as! DataSnapshot).value as! Bool
                    
                    if key == user.id {
                        if isFollowing {
                            cell.followButton.setTitle("Unfollow", for: UIControlState.normal)
                        }
                    }
                }
            })
        }
        cell.usernameLabel.text = user.fullName
        /*
        for (key, value) in suggestedUsers {
            if (key == user.id) {
                cell.usernameLabel.text = user.fullName + " - mutual:" + String(value)
            }
        }*/
        
        if let url = user.avatarUrl {
            cell.profilePicImage.sd_setImage(with: URL(string: url))
        } else {
            cell.profilePicImage.image = UIImage(named: "image1")
        }
        
        //cell.usernameLabel.text = user.fullName
    }
    
}

extension DiscoverViewController: UserCollectionViewCellDelegate {
    
    func sharePressed(cell: UserCollectionViewCell, isfollowing: Bool, countChange: Int) {
        
        let targetId: String
        
        guard let userId = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        
        if let index = userCollectionView.indexPath(for: cell)?.row {
            targetId = users[index].id
            service.followAndUnfollow(currentUid: userId, targetUid: targetId, willFollow: isfollowing, countChange: countChange, vc: self, cell: cell)
            
        } else if let index = searchUserCollection.indexPath(for: cell)?.row {
            targetId = searchUsers[index].id
            service.followAndUnfollow(currentUid: userId, targetUid: targetId, willFollow: isfollowing, countChange: countChange, vc: self, cell: cell)
            
        } else {
            service.errorAlert(controller: self, title: "Error", message: "UI collecction view index error")
            return
        }
        
        //self.userCollectionView.reloadData()
        //self.searchUserCollection.reloadData()
    }
    
    func didTapFollow(cell: UserCollectionViewCell) {
        print("did tap follow")
        sharePressed(cell: cell, isfollowing: true, countChange: 1)
        //ErrorHandler.errorAlert(controller: self, title: "Follow", message: "You tapped Follow")
    }
    
    func didTapUnfollow(cell: UserCollectionViewCell) {
        print("didtap unfollow")
        sharePressed(cell: cell, isfollowing: false, countChange: -1)
        //ErrorHandler.errorAlert(controller: self, title: "Unfollow", message: "You tapped Unfollow")
    }
}
