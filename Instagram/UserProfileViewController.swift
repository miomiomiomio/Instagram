//
//  ViewController.swift
//  Instagram
//
//  Created by user143023 on 9/18/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImage
import FirebaseStorage

class UserProfileViewController: UIViewController, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var loginInfoLabel: UILabel!
    @IBOutlet weak var imageCollection: UICollectionView!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var changeProfilePicButton: UIButton!
    @IBOutlet weak var followThisUserButton: UIButton!
    
    
    var customImageFlowLayout: CustomImageFlowLayout!
    var images = [Image]()
    var dbRef: DatabaseReference!
    let imagePicker = UIImagePickerController()
    var userRefPath: String?
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        let tapViewFollowing = UITapGestureRecognizer(target: self, action: #selector(UserProfileViewController.didTapViewFollowing))
        let tapViewFollower = UITapGestureRecognizer(target: self, action: #selector(self.didTapViewFollower))
        
        self.followingCountLabel.isUserInteractionEnabled = true
        self.followerCountLabel.isUserInteractionEnabled = true
        self.followingCountLabel.addGestureRecognizer(tapViewFollowing)
        self.followerCountLabel.addGestureRecognizer(tapViewFollower)
        
        Auth.auth().addStateDidChangeListener { auth, user in
            
        //let user = Auth.auth().currentUser
            
        if let user = user {
            
            let userId: String
            if self.userRefPath != nil {
                userId = self.userRefPath!
                
                let path = "user-following/\(user.uid)/following"
                Database.database().reference().child(path).observeSingleEvent(of:.value, with: { snapshot in
                    for child in snapshot.children {
                        let key = (child as! DataSnapshot).key
                        let isFollowing = (child as! DataSnapshot).value as! Bool
                        
                        if key == userId {
                            if isFollowing {
                                self.followThisUserButton.setTitle("Unfollow", for: UIControlState.normal)
                            }
                        }
                    }
                })
            } else {
                userId = user.uid
            }
            
            let userpostsRef = Database.database().reference().child("user-posts").child(userId).child("posts")
            userpostsRef.observe(.value, with: {snapshot in
                
                self.images = [Image]()
                self.imageCollection.reloadData()
                
                for child in snapshot.children {
                    let item = child as! DataSnapshot
                    let key = item.key
                    print(key)

                    let postsRef = Database.database().reference().child("posts").child(key)
                    //let query = postsRef.queryOrderedByKey().queryEqual(toValue: key)
                    
                    postsRef.observeSingleEvent(of: .value, with: { snapshot in
                        let photo = Image(snapshot: snapshot )
                        self.images.append(photo)
                        self.imageCollection.reloadData()
                    })
                    
                    /*
                    query.observeSingleEvent(of: .value, with: { snapshot in
                        
                        let value = snapshot.value as? NSDictionary
                        let url = value?["url"] as? String
                        
                        print(snapshot.value!)
                        print(snapshot.key)
                        
                        for child in snapshot.children {
                            
                            let item = child as! DataSnapshot
                            let dictionary = item.value as! [String: Any]
                            print(dictionary["url"]!)
                            
                        }
                    })
                    */
                }
            })
            // Update stats of user profile
            Database.database().reference().child("users").child(userId).observe( .value, with: { snapshot in
                let value = snapshot.value as? NSDictionary
                let user = User(snapshot: snapshot)
                self.loginInfoLabel.text = user.fullName
                
                let postCount = value?["post_count"] as? Int ?? 0
                let followerCount = value?["follower_count"] as? Int ?? 0
                let followingCount = value?["following_count"] as? Int ?? 0

                self.postCountLabel.text = String(postCount)
                self.followerCountLabel.text = String(followerCount)
                self.followingCountLabel.text = String(followingCount)
                
                self.postCountLabel.isHidden = false
                self.followerCountLabel.isHidden = false
                self.followingCountLabel.isHidden = false
                
                if let avatarUrl = value?["avatar_url"] {
                    self.profilePic.sd_setImage(with: URL(string: avatarUrl as! String), placeholderImage: UIImage(named: "image1"))
                } else {
                    self.profilePic.image = UIImage(named: "image1")
                }
            })
        } else {
            self.images = [Image]()
            self.imageCollection.reloadData()
            self.postCountLabel.isHidden = true
            self.followerCountLabel.isHidden = true
            self.followingCountLabel.isHidden = true
            self.profilePic.image = UIImage(named: "image1")
            }
        }
        
        customImageFlowLayout = CustomImageFlowLayout()
        imageCollection.collectionViewLayout = customImageFlowLayout
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            self.loginButton.isEnabled = false
            self.logoutButton.isEnabled = true
        } else {
            self.loginButton.isEnabled = true
            self.logoutButton.isEnabled = false
            self.loginInfoLabel.text = "Hello, please login"
        }
    }
    
    @objc func didTapViewFollowing(sender: UITapGestureRecognizer) {
        let userId: String
        if let user = Auth.auth().currentUser {
            if self.userRefPath != nil {
                userId = self.userRefPath!
            } else {
                userId = user.uid
            }

            let vc = storyboard?.instantiateViewController(withIdentifier:"UserCollectionViewController") as? UserCollectionViewController
            vc?.referencePath = "user-following/\(userId)/following"
            self.present(vc!, animated: true)
        } else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
        }
    }
    
    @objc func didTapViewFollower(sender: UITapGestureRecognizer) {
        let userId: String
        if let user = Auth.auth().currentUser {
            if self.userRefPath != nil {
                userId = self.userRefPath!
            } else {
                userId = user.uid
            }

            let vc = storyboard?.instantiateViewController(withIdentifier:"UserCollectionViewController") as? UserCollectionViewController
            vc?.referencePath = "user-follower/\(userId)/follower"
            self.present(vc!, animated: true)
        } else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
        }
    }

    @IBAction func logoutButtonClicked(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                
                self.loginButton.isEnabled = true
                self.logoutButton.isEnabled = false
                self.loginInfoLabel.text = "Hello please login"
                
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }
    }
    
    func collectionView(_ imageCollection: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ imageCollection: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollection.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCollectionViewCell
        
        let image = images[indexPath.row]
        
        cell.imageView.sd_setImage(with: URL(string: image.url), placeholderImage: UIImage(named: "image1"))
        return cell
    }
    
    @IBAction func didTapFollowOrUnfollow(_ sender: Any) {
        
        guard let currentUid = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        guard userRefPath != nil else {
            service.errorAlert(controller: self, title: "Error", message: "This user does not exist!")
            return
        }
        if (followThisUserButton.currentTitle == "Follow") {
            service.followAndUnfollow(currentUid: currentUid, targetUid: userRefPath!, willFollow: true, countChange: 1, vc: self, userProfileVC: self )
        }
        else if (followThisUserButton.currentTitle == "Unfollow") {
            service.followAndUnfollow(currentUid: currentUid, targetUid: userRefPath!, willFollow: false, countChange: -1, vc: self, userProfileVC: self )
        }
    }
    
    @IBAction func didTapChangeProfilePic(_ sender: Any) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true, completion: nil)
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            var data = Data()
            data = UIImageJPEGRepresentation(pickedImage, 1.0)!
            uploadProfilePic(data: data)
        }
    }
        
    func uploadProfilePic(data: Data) {
        
        guard let userId = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        
        let storageRef = Storage.storage().reference()
        let key = Date.timeIntervalSinceReferenceDate * 1000
        let imagePath = "\(userId)/avatar/\(key).jpg"
        let newMetadata = StorageMetadata()
        newMetadata.contentType = "image/jpeg"
        
        storageRef.child(imagePath).putData(data, metadata: nil) {
            (metadata, error) in
            guard error == nil else {
                service.errorAlert(controller: self, title: "Error", message: "Error uploading image")
                return
            }
            
            storageRef.child(imagePath).updateMetadata(newMetadata, completion: { metadata, error in
                if error != nil {
                    service.errorAlert(controller: self, title: "Error", message: "Error updating metadata")
                    return
                }
                
                storageRef.child(imagePath).downloadURL(completion: { url, error in
                    guard error == nil else {
                        service.errorAlert(controller: self, title: "Error", message: "Image URL does not exist")
                        return
                    }
                    
                    let dbRef = Database.database().reference()
                    let imageUrl = url?.absoluteString
                    let path = "users/\(userId)"
                    let data : [String: AnyObject] = ["avatar_url": imageUrl as AnyObject]
                    dbRef.child(path).updateChildValues(data)
                })
            })
        }
    }
 
}
