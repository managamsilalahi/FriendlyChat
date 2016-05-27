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
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msgLength: NSNumber = 25
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    private var _refHandle: FIRDatabaseHandle!
    
    
    // MARK: Life cycle
    override func viewWillAppear(animated: Bool) {
        
        self.freshConfigButton.hidden = true
        self.crashButton.hidden = true
        
        //getFirebaseSnapshot()

    }
    
    func getFirebaseSnapshot() {
        
        self.spinner.startAnimating()
        self.messages.removeAll()
        self.tableView.beginUpdates()
        
        // Listen for new messsages in the Firebase database
        self._refHandle = self.ref.child("messages").observeEventType(.ChildAdded, withBlock: { (snapshot) in

            self.messages.append(snapshot)
            //self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.messages.count-1, inSection: 0)], withRowAnimation: .Automatic)

            self.tableView.reloadData()
            
        })
        
        self.tableView.endUpdates()
        self.spinner.stopAnimating()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        loadAd()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
        fetchConfig()
        configureStorage()
        
        // Loading
        self.spinner.hidesWhenStopped = true
        self.spinner.center = view.center
        self.view.addSubview(self.spinner)
        self.spinner.startAnimating()
        
        // Get Firebase Snapshot
        self.getFirebaseSnapshot()
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
    
    // Without Firebase Storage
    /* func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
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
        
    } */
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Dequeue cell
        let cell = self.tableView.dequeueReusableCellWithIdentifier("messageCell")
        
        // Unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
        let message = messageSnapshot.value as! Dictionary<String, String>
        let name = message[Constants.MessageFields.name] as String!
        
        if let imageUrl = message[Constants.MessageFields.imageUrl] {
            
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
                    
                    if let error = error {
                        print("Error downloading: \(error)")
                        return
                    }
                    
                    cell?.imageView?.image = UIImage.init(data: data!)
                    
                })
            } else if let url = NSURL(string: imageUrl), data = NSData(contentsOfURL: url) {
                cell?.imageView?.image = UIImage.init(data: data)
            }
            
            cell?.textLabel?.text = "Sent by: \(name)"
            
        } else {
            
            let text = message[Constants.MessageFields.text] as String!
            cell?.textLabel?.text = name + ": " + text
            cell?.textLabel?.numberOfLines = 0
            cell?.imageView?.image = UIImage(named: "ic_account_circle")
            
            if let photoUrl = message[Constants.MessageFields.photoUrl], url = NSURL(string: photoUrl), data = NSData(contentsOfURL: url) {
                
                cell?.imageView?.image = UIImage(data: data)
                
            }
            
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
        
        let whiteSpace = NSCharacterSet.whitespaceCharacterSet()
        
        if self.textField.text!.stringByTrimmingCharactersInSet(whiteSpace) != "" {
            // string contains non-whitespace characters
            textFieldShouldReturn(textField)
            self.textField.text = ""
            
            
        }
        
        

        
    }
    
    
    // Helper Function
    func loadAd() {
        
    }
    
    func fetchConfig() {
        
    }
    
    func configureStorage() {
        self.storageRef = FIRStorage.storage().referenceForURL("gs://friendlychat-e82af.appspot.com")
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
    
    @IBAction func didTapAddPhoto(sender: AnyObject) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker.sourceType = .Camera
        } else {
            picker.sourceType = .PhotoLibrary
        }
        
        self.presentViewController(picker, animated: true, completion:nil)
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        let referenceUrl = info[UIImagePickerControllerReferenceURL] as! NSURL
        let assets = PHAsset.fetchAssetsWithALAssetURLs([referenceUrl], options: nil)
        let asset = assets.firstObject
        
        asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, info) in
            
            let imageFile = contentEditingInput?.fullSizeImageURL
            let filePath = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))\(referenceUrl.lastPathComponent!)"
            let metadata = FIRStorageMetadata()
            self.storageRef.child(filePath).putFile(imageFile!, metadata: metadata, completion: { (metadata, error) in
                
                if let error = error {
                    print("error upload: \(error.description)")
                    return
                }
                
                self.sendMessage([Constants.MessageFields.imageUrl: self.storageRef.child((metadata?.path)!).description])
                
                
            })
            
        })
        
    }
    
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
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
