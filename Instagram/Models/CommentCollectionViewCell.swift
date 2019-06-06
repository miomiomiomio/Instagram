//
//  CommentCollectionViewCell.swift
//  Instagram
//
//  Created by user143023 on 10/10/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit

class CommentCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentText: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
}
