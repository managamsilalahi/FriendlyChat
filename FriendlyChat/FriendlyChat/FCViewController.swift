//
//  FCViewController.swift
//  FriendlyChat
//
//  Created by Admin on 5/26/16.
//  Copyright © 2016 Managam. All rights reserved.
//

import UIKit
import Photos

import Firebase

class FCViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Instance variables
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var banner: GADBannerView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var freshConfigButton: UIButton!
    @IBOutlet weak var crashButton: UIButton!
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msgLength: NSNumber = 10
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    private var _refHandle: FIRDatabaseHandle!
    
    
    
    // MARK: Life cycle
    override func viewWillAppear(animated: Bool) {
        self.freshConfigButton.hidden = true
        self.crashButton.hidden = true
        
        self.messages.removeAll()
        
        // Listen for new messsages in the Firebase database
        _refHandle = self.ref.child("messages").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            
            self.messages.append(snapshot)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.messages.count-1, inSection: 0)], withRowAnimation: .Automatic)
            
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        loadAd()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
        fetchConfig()
        configureStorage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.ref.removeObserverWithHandle(_refHandle)
    }
    
    
    
    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Dequeue cell
        let cell = self.tableView.dequeueReusableCellWithIdentifier("messageCell")
        
        // Unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
        let message = messageSnapshot.value as! Dictionary<String, String>
        let name = message[Constants.MessageFields.name] as String!
        let text = message[Constants.MessageFields.text] as String!
        
        cell?.textLabel?.text = name + ": " + text
        cell?.imageView?.image = UIImage(named: "ic_account_circle")
        
        if let photoUrl = message[Constants.MessageFields.photoUrl], url = NSURL(string: photoUrl), data = NSData(contentsOfURL: url) {
            cell?.imageView?.image = UIImage(data: data)
        }
        
        return cell!
        
    }

    @IBAction func signOut(sender: UIButton) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            performSegueWithIdentifier(Constants.Segues.FpToSignIn, sender: nil)
        } catch let signOutError as NSError {
            print("Error signin out: \(signOutError)")
        }
    }
    
    @IBAction func didSendMessage(sender: UIButton) {
        textFieldShouldReturn(textField)
    }
    
    
    // Helper Function
    func loadAd() {
        
    }
    
    func fetchConfig() {
        
    }
    
    func configureStorage() {
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        
        return newLength <= self.msgLength.integerValue // Bool
    }
    
    func sendMessage(data: [String: String]){
        var mdata = data
        mdata[Constants.MessageFields.name] = AppState.sharedInstance.displayName
        if let photoUrl = AppState.sharedInstance.photoUrl {
            mdata[Constants.MessageFields.photoUrl] = photoUrl.absoluteString
        }
        
        // Push data to Firebase Database
        self.ref.child("messages").childByAutoId().setValue(mdata)
    }
    
    // UITextViewDelegate protocol methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let data = [Constants.MessageFields.text : textField.text! as String]
        sendMessage(data)
        return true
    }
    
    
    // MARK: - Image Picker
    
    @IBAction func didTapAddPhoto(sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            picker.sourceType = .Camera
        } else {
            picker.sourceType = .PhotoLibrary
        }
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        let referenceUrl = info[UIImagePickerControllerReferenceURL] as! NSURL
        let assets = PHAsset.fetchAssetsWithALAssetURLs([referenceUrl], options: nil)
        let asset = assets.firstObject
        
        asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, info) in
            
            let imageFile = contentEditingInput?.fullSizeImageURL
            let filePath = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))\(referenceUrl.lastPathComponent!)"
            
        })
        
    }
    
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showAlert(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue()) { 
            
            let alert = UIAlertController.init(title: title, message: message, preferredStyle: .Alert)
            let dismissAction = UIAlertAction.init(title: "Dismiss", style: .Destructive, handler: nil)
            alert.addAction(dismissAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
}
