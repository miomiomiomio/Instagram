//
//  AlertProtocol.swift
//  MPChat
//
//  Created by Meng Yang on 27/08/2017.
//  Copyright © 2017 MelbUni. All rights reserved.
//

import UIKit

protocol AlertProtocol {}

extension AlertProtocol where Self: UIViewController {
    
    func createAlertWithMsgAndTitle(_ title: String, msg: String) {
        
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Accept", style: .cancel, handler: { (alert) -> Void in
            alertController.removeFromParentViewController()
        }))
        
        present(alertController, animated: true, completion: nil)
        
    }
    
}
