//
//  UserCollectionViewCell.swift
//  Instagram
//
//  Created by user143023 on 10/3/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit

protocol UserCollectionViewCellDelegate: class {
    func sharePressed(cell: UserCollectionViewCell, isfollowing: Bool, countChange: Int)
    func didTapFollow(cell: UserCollectionViewCell)
    func didTapUnfollow(cell: UserCollectionViewCell)
}

class UserCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var profilePicImage: UIImageView!
    
    var delegate: UserCollectionViewCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.followButton.setTitle("Follow", for: UIControlState.normal)
    }
    
    @IBAction func didTapButton(_ sender: UIButton) {
        //delegate?.sharePressed(cell: self)
        print("---------  this line only executes once?")
        if (self.followButton.currentTitle == "Follow"){
            print("did tap follow button")

            delegate?.didTapFollow(cell: self)
        }
        if(self.followButton.currentTitle == "Unfollow"){
            print("did tap Unfollow button")

            delegate?.didTapUnfollow(cell: self)
        }
    }
    
}
