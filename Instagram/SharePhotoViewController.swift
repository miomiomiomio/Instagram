//  Created by Chai Li 16/08/2018
//  Reference: tutorial 4 from unimelb by Meng Yang on 27/08/2017.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, AlertProtocol {
    
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatView: UITextView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var receivedPhoto: UIImageView!
    
    let serviceType = "MPChat"
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add tap gesture to chat view to dismiss keyboard
//        let tapGuesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
//        tapGuesture.cancelsTouchesInView = false
//        chatView.addGestureRecognizer(tapGuesture)
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // the browser
        self.browser = MCBrowserViewController(serviceType: serviceType, session: self.session)
        self.browser.delegate = self
        
        // the advertiser
        self.assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: self.session)
        // start advertising
        self.assistant.start()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        NotificationCenter.default.addObserver(self,
//                                                         selector: #selector(keyboardWillShow(_:)),
//                                                         name: NSNotification.Name.UIKeyboardWillShow,
//                                                         object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                                         selector: #selector(keyboardWillHide(_:)),
//                                                         name: NSNotification.Name.UIKeyboardWillHide,
//                                                         object: nil)
    }

    @IBAction func showBrowser(_ sender: UIButton) {
        // show the browser view controller
        self.present(self.browser, animated: true, completion: nil)
        
    }
    
    @IBAction func sendChat(_ sender: UIButton) {
        
        let msg = self.messageField.text!.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        do {
            try self.session.send(msg!, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            
            self.updateChat(self.messageField.text!, fromPeer: self.peerID)
            
            self.messageField.text = ""
            
        } catch let error as NSError {
            createAlertWithMsgAndTitle("Error", msg: error.localizedDescription)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // browser delegate's methods
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        // "Done" was tapped
        self.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        // "Cancel" was tapped
        self.dismiss(animated: true, completion: nil)
    }
    
    // session delegate's methods
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let image = UIImage(data: data) {
            DispatchQueue.main.async { [unowned self] in
                self.receivedPhoto.image = image
                self.receivedPhoto.reloadInputViews()
            }
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }

    // MARK: Keyboard notification

    @objc func keyboardWillShow(_ sender: Notification) {
        if let keyboardFrame = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            UIView.animate(withDuration: 0.5, animations: { 
                self.bottomViewConstraint.constant = keyboardHeight
                }, completion: { (completed) in
                    if completed {
                         self.chatView.scrollRangeToVisible(NSMakeRange(self.chatView.text.characters.count-1, 0))
                    }
                   
            })
            
        }
    }
    
//    @objc func keyboardWillHide(_ sender: Notification) {
//
//        UIView.animate(withDuration: 0.5, animations: {
//            self.bottomViewConstraint.constant = 0
//        })
//
//    }
//
//    @objc func dismissKeyboard(_ sender:UITapGestureRecognizer) {
//        messageField.resignFirstResponder()
//    }
    
    func updateChat(_ text: String, fromPeer peerID: MCPeerID) {
        var name: String
        
        switch peerID {
        case self.peerID:
            name = "Me"
        default:
            name = peerID.displayName
        }
        
        let message = "\(name): \(text)\n"
        self.chatView.text = self.chatView.text + message
        chatView.scrollRangeToVisible(NSMakeRange(chatView.text.characters.count, 0))
    }

    @IBAction func sendPhoto(_ sender: Any) {
   
        let actionSheet = UIAlertController(title: "PHOTO SOURCE", message: nil, preferredStyle: .actionSheet)
        
        //photo source - camera
        actionSheet.addAction(UIAlertAction(title: "CAMERA", style: .default, handler: { alertAction in
            self.showImagePickerForSourceType(.camera)
        }))
        
        //photo source - photo library
        actionSheet.addAction(UIAlertAction(title: "PHOTO LIBRARY", style: .default, handler: { alertAction in
            self.showImagePickerForSourceType(.photoLibrary)
        }))
        
        //cancel button
        actionSheet.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler:nil))
        
        present(actionSheet, animated: true, completion: nil)
    
    
    }
    
    func showImagePickerForSourceType(_ sourceType: UIImagePickerControllerSourceType) {
        
        DispatchQueue.main.async(execute: {
            let imagePickerController = UIImagePickerController()
            imagePickerController.allowsEditing = true
            imagePickerController.modalPresentationStyle = .currentContext
            imagePickerController.sourceType = sourceType
            ////////////////////////////////////////
            /*
             We actually have two delegates:UIImagePickerControllerDelegate and UINavigationControllerDelegate. The UINavigationControllerDelegate is required but we do nothing with it.
             Add the following:
             */
            imagePickerController.delegate = self
            
            self.present(imagePickerController, animated: true, completion: nil)
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImagePickerControllerDelegate_Protocol/index.html#//apple_ref/doc/constant_group/Editing_Information_Keys
        
        picker.dismiss(animated: true) {
            
            print("media type: \(String(describing: info[UIImagePickerControllerMediaType]))")
            
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                self.receivedPhoto.image = image
                self.receivedPhoto.contentMode = .scaleAspectFit
                self.sendImage(img: image)
            }
            
            
        }
    }
    
    func sendImage(img: UIImage) {
        if self.session.connectedPeers.count > 0 {
            if let imageData = UIImagePNGRepresentation(img) {
                do {
                    try self.session.send(imageData, toPeers: self.session.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
}



