//
//  ImageCollectionViewCell.swift
//  Instagram
//
//  Created by user143023 on 9/18/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}
