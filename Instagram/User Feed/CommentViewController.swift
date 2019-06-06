//
//  CommentViewController.swift
//  Instagram
//
//  Created by user143023 on 10/8/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class CommentViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{

    
    @IBOutlet weak var commentCollection: UICollectionView!
    
    var comments = [Comment]()
    let dbRef = Database.database().reference()
    var postId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dbRef.child("post-comment").child(postId).child("comments").observe(.value, with: { snapshot in
            for child in snapshot.children {
                let key = (child as! DataSnapshot).key
                
                self.dbRef.child("comments").child(key).observe(.value, with: {snapshot in
                    let comment = Comment(snapshot: snapshot)
                    self.comments.append(comment)
                    self.commentCollection.reloadData()

                })
            }
        })

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CommentCollectionViewCell
        
        let comment = comments[indexPath.row]
        let path = "users/\(comment.userId)"
        dbRef.child(path).observe(.value, with: { snapshot in
            let user = User(snapshot: snapshot)
            cell.usernameLabel.text = user.fullName
            if let url = user.avatarUrl {
                cell.profilePicImageView.sd_setImage(with: URL(string: url))
            } else {
                cell.profilePicImageView.image = UIImage(named: "image1")
            }
        })
        
        cell.commentText.text = comment.message

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy hh:mm a"
        let date = Date(timeIntervalSince1970: comment.time/1000)
        cell.timeLabel.text = formatter.string(from: date)
        return cell
    }
    

    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
