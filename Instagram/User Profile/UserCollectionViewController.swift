//
//  UserCollectionViewController.swift
//  Instagram
//
//  Created by user143023 on 10/14/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class UserCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var userCollectionView: UICollectionView!
    
    var users = [User]()
    let dbRef = Database.database().reference()
    var referencePath: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userCollectionView.delegate = self
        userCollectionView.dataSource = self
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                if self.referencePath != nil {
                    self.getUserCollection(path: self.referencePath!)
                }
            } else {
                self.users = [User]()
                self.userCollectionView.reloadData()
            }
        }

    }
    
    func getUserCollection(path: String) {
        dbRef.child(path).observe(.value, with: { snapshot in
            self.users = [User]()
            for child in snapshot.children {
                let isFollowing = (child as! DataSnapshot).value as! Bool
                let key = (child as! DataSnapshot).key
                
                if(isFollowing) {
                    self.dbRef.child("users").child(key).observe(.value, with: { snapshot in
                        let user = User(snapshot: snapshot)
                        var isNewUser = true
                        for (index, value) in self.users.enumerated() {
                            if (value.id == user.id) {
                                self.users[index] = user
                                isNewUser = false
                            }
                        }
                        if isNewUser {
                            self.users.append(user)
                        }
                        self.userCollectionView.reloadData()
                    })
                }
            }
        })
    }
    
    @objc func didTapViewUser(sender: CustomTapGesture) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "UserProfileVC") as? UserProfileViewController
        vc?.userRefPath = sender.id
        self.present(vc!, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! UserCollectionViewCell
        let user = users[indexPath.row]
        if let userId = Auth.auth().currentUser?.uid {
            let path = "user-following/\(userId)/following"
            dbRef.child(path).observe(.value, with: { snapshot in
                for child in snapshot.children {
                    let key = (child as! DataSnapshot).key
                    let isFollowing = (child as! DataSnapshot).value as! Bool
                    
                    if key == user.id && isFollowing {
                        cell.followButton.setTitle("Unfollow", for: UIControlState.normal)
                    }
                }
            })
        }
        cell.usernameLabel.text = user.fullName
        
        if let url = user.avatarUrl {
            cell.profilePicImage.sd_setImage(with: URL(string: url))
        } else {
            cell.profilePicImage.image = UIImage(named: "image1")
        }

        let tapViewUser = CustomTapGesture(target: self, action: #selector(self.didTapViewUser))
        tapViewUser.id = user.id
        cell.usernameLabel.isUserInteractionEnabled = true
        cell.usernameLabel.addGestureRecognizer(tapViewUser)
        
        cell.delegate = self
        return cell
    }

    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)

    }

}

class CustomTapGesture: UITapGestureRecognizer {
    var id = String()
}

extension UserCollectionViewController: UserCollectionViewCellDelegate {
    
    func sharePressed(cell: UserCollectionViewCell, isfollowing: Bool, countChange: Int) {
        
        let targetId: String
        
        guard let userId = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        
        if let index = userCollectionView.indexPath(for: cell)?.row {
            targetId = users[index].id
            service.followAndUnfollow(currentUid: userId, targetUid: targetId, willFollow: isfollowing, countChange: countChange, vc: self, cell: cell)
            
        } else {
            service.errorAlert(controller: self, title: "Error", message: "UI collecction view index error")
            return
        }
        
    }
    
    func didTapFollow(cell: UserCollectionViewCell) {
        sharePressed(cell: cell, isfollowing: true, countChange: 1)
    }
    
    func didTapUnfollow(cell: UserCollectionViewCell) {
        sharePressed(cell: cell, isfollowing: false, countChange: -1)
    }
}
