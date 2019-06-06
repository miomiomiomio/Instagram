//
//  PostCollectionViewCell.swift
//  Instagram
//
//  Created by user143023 on 10/3/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit

protocol PostCollectionCellDelegate: class {
    func tapLikeButton(cell: PostCollectionViewCell, isLiking: Bool, countChange: Int)
    func didTapLike(cell: PostCollectionViewCell)
    func didTapUnlike(cell: PostCollectionViewCell)
    func didTapSendComment(cell: PostCollectionViewCell, message: String)
    func didTapViewComment(cell: PostCollectionViewCell)
}

class PostCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var viewCommentButton: UIButton!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var postMessageLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var postId: String?
    
    var delegate: PostCollectionCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.likeButton.setTitle("Like", for: UIControlState.normal)
        self.locationLabel.isHidden = false
        self.postMessageLabel.isHidden = false
    }
    
    @IBAction func didTapViewComment(_ sender: Any) {
        delegate?.didTapViewComment(cell: self)
    }
    
    @IBAction func didTapLikeButton(_ sender: Any) {
        
        if(self.likeButton.currentTitle == "Like"){
            delegate?.didTapLike(cell: self)
        }
        if(self.likeButton.currentTitle == "Unlike") {
            delegate?.didTapUnlike(cell: self)
        }
    }
    
    @IBAction func didTapSendComment(_ sender: Any) {
        
        if (commentTextField.text != ""){
            delegate?.didTapSendComment(cell: self, message: commentTextField.text!)
            commentTextField.text = nil
        }
    }
}
