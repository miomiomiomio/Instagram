//
//  PostUploadViewController.swift
//  Instagram
//
//  Created by user143023 on 9/27/18. Modified by Chai on 10/19/18.
//  Copyright © 2018 zhitao. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SDWebImage
import CoreImage

class PostUploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let imagePicker = UIImagePickerController()
    var dbRef: DatabaseReference!
    let errorHandler = service()
    
    @IBOutlet weak var newPhoto: UIImageView!
    @IBOutlet weak var photoOriginal: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        dbRef = Database.database().reference().child("image")

        // Do any additional setup after loading the view.
    }
    @IBAction func getImage(_ sender: Any) {
        showActionSheet()
    }
    
    @IBAction func applySepia(_ sender: Any) {
            newPhoto.image = applyFilterTo(image: photoOriginal.image!, filterEffect: Filter(filterName: "CISepiaTone", filterEffectValue: 0.70, filterEffectValueName: kCIInputIntensityKey))
    }
    
    @IBAction func applyNoir(_ sender: Any) {
            newPhoto.image = applyFilterTo(image: photoOriginal.image!, filterEffect: Filter(filterName: "CIPhotoEffectNoir", filterEffectValue: nil, filterEffectValueName: nil))
    }
    
    @IBAction func applyProcessEffect(_ sender: Any) {
            newPhoto.image = applyFilterTo(image: photoOriginal.image!, filterEffect: Filter(filterName: "CIPhotoEffectProcess", filterEffectValue: nil, filterEffectValueName: nil))
    }
    
    
    @IBAction func reset(_ sender: Any) {
        newPhoto.image = photoOriginal.image
    }
    
    @IBAction func brightness(_ sender: UISlider) {
        newPhoto.image = applyFilterTo(image: photoOriginal.image!, filterEffect: Filter(filterName: "CIColorControls", filterEffectValue: sender.value/100, filterEffectValueName: kCIInputBrightnessKey))
    }
    
    
    @IBAction func contrast(_ sender: UISlider) {
            newPhoto.image = applyFilterTo(image: photoOriginal.image!, filterEffect: Filter(filterName: "CIColorControls", filterEffectValue: 1+sender.value/100, filterEffectValueName: kCIInputContrastKey))
    }
    
    @IBAction func upload(_ sender: UIButton) {
        var data = Data()
        data = UIImageJPEGRepresentation(newPhoto.image!, 1.0)!
        uploadImage(data: data)
    }
    
    @IBAction func editPost(_ sender: Any) {
        guard newPhoto.image != nil else {
            service.errorAlert(controller: self, title: "Error", message: "Please select a photo first!")
            return
        }
        let vc = storyboard?.instantiateViewController(withIdentifier: "PostEditVC") as? PostEditViewController
        vc?.postImage = newPhoto.image
        self.present(vc!, animated: true)
        
    }
    
    struct Filter {
        let filterName: String
        var filterEffectValue: Any?
        var filterEffectValueName: String?
        
        init(filterName: String, filterEffectValue: Any?, filterEffectValueName: String?) {
            self.filterName = filterName
            self.filterEffectValue = filterEffectValue
            self.filterEffectValueName = filterEffectValueName
        }
    }
    private func applyFilterTo(image: UIImage, filterEffect: Filter) -> UIImage? {
        
        guard let cgImage = image.cgImage,
            let openGLContext = EAGLContext(api: .openGLES3) else {
                return nil
        }
        
        let context = CIContext(eaglContext: openGLContext)
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: filterEffect.filterName)
        
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let filterEffectValue = filterEffect.filterEffectValue,
            let filterEffectValueName = filterEffect.filterEffectValueName {
            filter?.setValue(filterEffectValue, forKey: filterEffectValueName)
        }
        
        var filteredImage: UIImage?
        
        if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage,
            let cgiImageResult = context.createCGImage(output, from: output.extent) {
            filteredImage = UIImage(cgImage: cgiImageResult, scale: 1.0, orientation: UIImage.Orientation.up)
        }
        
        
        return filteredImage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func uploadImage(data: Data) {
        guard let userId = Auth.auth().currentUser?.uid else {
            service.errorAlert(controller: self, title: "Error", message: "Please log in first")
            return
        }
        
        let storageRef = Storage.storage().reference()
        let key = Date.timeIntervalSinceReferenceDate * 1000
        let imagePath = "\(userId)/posts/\(key).jpg"
        let newMetadata = StorageMetadata()
        newMetadata.contentType = "image/jpeg"
        
        // Upload image to Firebase storage
        storageRef.child(imagePath).putData(data, metadata: nil) {
            (metadata, error) in
            guard error == nil else {
                service.errorAlert(controller: self, title: "Error", message: "Failed upload image.")
                return
            }
            // Update metadata
            storageRef.child(imagePath).updateMetadata(newMetadata) { metadata, error in
                if let error = error {
                    service.errorAlert(controller: self, title: "Error", message: "Error updating metadata")
                    print(error)
                }
                // Get the download url of image from the Firebase storage
                storageRef.child(imagePath).downloadURL { url,error in
                    guard error == nil else {
                        service.errorAlert(controller: self, title: "Error", message: "Image URL does not exist.")
                        return
                    }
                    // Update the "photos" table in DB
                    let databaseRef = Database.database().reference()
                    let key = databaseRef.child("photos").childByAutoId().key
                    let imageUrl = url?.absoluteString
                    let path = "photos/\(key ?? "defaultpath")"
                    let data : [String: AnyObject] = [
                        "id": key as AnyObject,
                        "uid": userId as AnyObject,
                        "url": imageUrl as AnyObject
                    ]
                    databaseRef.child(path).setValue(data)
                    
                    // Update the "posts" table in DB
                    let postpath = "posts/\(key!)"
                    let postdata : [String: AnyObject] = [
                        "id": key as AnyObject,
                        "uid": userId as AnyObject,
                        "timestamp": ServerValue.timestamp() as AnyObject,
                        "likes_count": 0 as AnyObject,
                        "comments_count" : 0 as AnyObject,
                        "url": imageUrl as AnyObject
                        ]
                    databaseRef.child(postpath).setValue(postdata)
                    
                    // Update the "user-posts" table in DB
                    let userpostpath = "user-posts/\(userId)/posts"
                    let userpostdata : [String : AnyObject] = [
                        key!: true as AnyObject
                    ]
                    databaseRef.child(userpostpath).updateChildValues(userpostdata)
                    
                    // Update the post count value in the "user" table
                    let userRef = Database.database().reference().child("users").child(userId)
                    userRef.observeSingleEvent(of: .value, with: { snapshot in
                        let value = snapshot.value as? NSDictionary
                        var postCount = value?["post_count"] as! Int
                        postCount += 1
                        let newPostCount:[String:Int] = ["post_count":postCount]
                        userRef.updateChildValues(newPostCount)
                    })
                    
                }
            }
        }
    }
    
    
    func showActionSheet() {
        
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
    
    /////////////////////////////////////////////////
    /*
     These two methods handle our selections in the library and camera. We can either handle the cancel case with cancel button or handle media with didFinishPickingMediaWithInfo
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImagePickerControllerDelegate_Protocol/index.html#//apple_ref/doc/constant_group/Editing_Information_Keys
        
        picker.dismiss(animated: true) {
            
            print("media type: \(String(describing: info[UIImagePickerControllerMediaType]))")
            
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                self.photoOriginal.image = image            }
        }
    }
    
    
    
    
    

}
