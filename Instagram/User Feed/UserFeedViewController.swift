//
//  UserFeedViewController.swift
//  Instagram
//
//  Created by user143023 on 9/26/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class UserFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var postCollection: UICollectionView!
    
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Auth.auth().addStateDidChangeListener { auth, user in
            
            if let user = user {

                let dbRef = Database.database().reference()
                
                dbRef.child("user-following").child(user.uid).child("following").observe(.value, with: { snapshot in
                    self.posts = [Post]()
                    
                    for child in snapshot.children {
                        let isFollowing = (child as! DataSnapshot).value as! Bool
                        let key = (child as! DataSnapshot).key
                        if (isFollowing) {
                            self.addPostToDataSource(userId: key)
                        }
                    }
                    
                    self.addPostToDataSource(userId: user.uid)
                })
                
            } else {
                self.posts = [Post]()
                self.postCollection.reloadData()
            }
        }
    }

    func addPostToDataSource(userId:String) {
        let dbRef = Database.database().reference()
        let path = "user-posts/\(userId)/posts"
        dbRef.child(path).observe(.value, with: { snapshot in
            
            for child in snapshot.children {
                let key = (child as! DataSnapshot).key
                let path = "posts/\(key)"
                dbRef.child(path).observe(.value, with: { snapshot in
                    
                    let post = Post(snapshot: snapshot)
                    var isNewpost = true
                    for (index,value) in self.posts.enumerated() {
                        if (value.key == post.key) {
                            self.posts[index] = post
                            isNewpost = false
                        }
                    }
                    if (isNewpost) {
                        self.posts.append(post)
                    }
                    self.postCollection.reloadData()
                })
            }
        })
    }
    
    @IBAction func sortPostbyDecreasingDate(_ sender: Any) {
        posts.sort(by: { $0.time > $1.time})
        self.postCollection.reloadData()
    }
    @IBAction func sortPostbyIncreasingDate(_ sender: Any) {
        posts.sort(by: { $0.time < $1.time})
        self.postCollection.reloadData()
    }
    
    @IBAction func sortPostbyIncreasingLocation(_ sender: Any) {
        posts.sort(by: { $0.location ?? "a" > $1.location ?? "a" })
        self.postCollection.reloadData()
    }
    
    @IBAction func sortPostbyDecreasingLocation(_ sender: Any) {
        posts.sort(by: { $0.location ?? "a" < $1.location ?? "a" })
        self.postCollection.reloadData()
    }
    
    @objc func didTapViewUsersLiked(sender: CustomTapGesture) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "UserCollectionViewController") as? UserCollectionViewController
        vc?.referencePath = sender.id
        self.present(vc!, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PostCollectionViewCell
        
        let post = posts[indexPath.row]
        let dbRef = Database.database().reference()
        
        if let userId = Auth.auth().currentUser?.uid {
            let path = "user-like/\(userId)/likes"
            dbRef.child(path).observe(.value, with: { snapshot in
                for child in snapshot.children {
                    let key = (child as! DataSnapshot).key
                    let isLiking = (child as! DataSnapshot).value as! Bool
                    
                    if key == post.key && isLiking {
                        cell.likeButton.setTitle("Unlike", for: UIControlState.normal)
                    }
                }
            })
        }
        
        dbRef.child("users").child(post.userId).observe(.value, with: { snapshot in
            let user = User(snapshot: snapshot)
            //print(snapshot)
            cell.userName.text = user.fullName
            if let url = user.avatarUrl {
                cell.profilePicImageView.sd_setImage(with: URL(string: url))
            } else {
                cell.profilePicImageView.image = UIImage(named: "image1")
            }
        })
        
        cell.postId = post.key
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy hh:mm a"
        let date = Date(timeIntervalSince1970: post.time/1000)
        cell.timeLabel.text = formatter.string(from: date)
        //cell.userName.text = post.userId
      /*  if post.likeCount == 0 {
            cell.likeCount.isHidden = true
        } else */
        if post.likeCount <= 1 {
            cell.likeCount.text = String(post.likeCount) + " like"
        } else {
            cell.likeCount.text = String(post.likeCount) + " likes"
        }
        cell.viewCommentButton.setTitle(String(post.commentCount) + " comments", for: UIControlState.normal)
        cell.imageView.sd_setImage(with: URL(string: post.url), placeholderImage: UIImage(named: "image1"))
        
        let tapViewUser = CustomTapGesture(target: self, action:#selector(self.didTapViewUsersLiked))
        tapViewUser.id = "post-like/\(post.key)/likes"
        cell.likeCount.isUserInteractionEnabled = true
        cell.likeCount.addGestureRecognizer(tapViewUser)
        
        if post.location != nil {
            let location = "@ " + post.location!
            cell.locationLabel.text = location
        } else {
            cell.locationLabel.isHidden = true
        }
        
        if post.message != nil {
            cell.postMessageLabel.text = post.message
        } else {
            cell.postMessageLabel.isHidden = true
        }
        
        cell.delegate = self
        
        return cell
    }
}

extension UserFeedViewController: PostCollectionCellDelegate {
    
    func didTapViewComment(cell: PostCollectionViewCell) {
        //performSegue(withIdentifier: "viewComment", sender: cell)
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "CommentViewController") as? CommentViewController
        vc?.postId = cell.postId!
        
        self.present(vc!, animated: true)
 
    }
    
    func tapLikeButton(cell: PostCollectionViewCell, isLiking: Bool, countChange: Int) {
        guard let index = postCollection.indexPath(for: cell)?.row else {
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        
        let postId = posts[index].key
        
        LikeService.likeAndUnlike(userId: userId, postId: postId, isLiking: isLiking, countChange: countChange)
        
        /*
        let postLikePath = "post-like/\(postId)/likes"
        let userLikePath = "user-like/\(userId)/likes"
        let postLikeData: [String: Bool] = [userId: isLiking]
        let userLikeData: [String: Bool] = [postId: isLiking]
        
        dbRef.child(postLikePath).updateChildValues(postLikeData)
        dbRef.child(userLikePath).updateChildValues(userLikeData)
        
        // Update the like count value in "posts" table
        let postRef = dbRef.child("posts").child(postId)
        postRef.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            var likeCount = value?["likes_count"] as! Int
            likeCount += countChange
            let newCount: [String:Int] = ["likes_count":likeCount]
            postRef.updateChildValues(newCount)
        })
 */
        self.postCollection.reloadData()
    }
    
    func didTapLike(cell: PostCollectionViewCell) {
        tapLikeButton(cell: cell, isLiking: true, countChange: 1)
    }
    
    func didTapUnlike(cell: PostCollectionViewCell) {
        tapLikeButton(cell: cell, isLiking: false, countChange: -1)
    }
    
    func didTapSendComment(cell: PostCollectionViewCell, message: String) {
        guard let index = postCollection.indexPath(for: cell)?.row else {
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        // update the "comments" table in DB
        let dbRef = Database.database().reference()
        let key = dbRef.child("comments").childByAutoId().key
        let postId = posts[index].key
        let path = "comments/\(key!)"
        let data = [
            "id": key!,
            "uid": userId,
            "pid": postId,
            "message": message,
            "timestamp": ServerValue.timestamp()
        ] as [String: AnyObject]
        dbRef.child(path).setValue(data)
        
        // update the "post-comment" table in DB
        let postCommentPath = "post-comment/\(postId)/comments"
        let postCommentData : [String: Bool] = [key!: true]
        dbRef.child(postCommentPath).updateChildValues(postCommentData)
        
        // update the "user-comment" table in DB
        let userCommentPath = "user-comment/\(userId)/comments"
        let userCommentData : [String: Bool] = [key!: true]
        dbRef.child(userCommentPath).updateChildValues(userCommentData)
        
        // update the comment count in "posts" table
        let postPath = "posts/\(postId)"
        dbRef.child(postPath).observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            var commentCount = value?["comments_count"] as! Int
            commentCount += 1
            let newCount: [String: Int] = ["comments_count": commentCount]
            dbRef.child(postPath).updateChildValues(newCount)
        })
        
        service.errorAlert(controller: self, title: "Notification", message: "Your comment is posted")
    }
    
}
