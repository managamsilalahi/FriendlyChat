//
//  FCViewController.swift
//  FriendlyChat
//
//  Created by Admin on 5/26/16.
//  Copyright © 2016 Managam. All rights reserved.
//

import UIKit
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
    
    
    // Helper Function
    func loadAd() {
        
    }
    
    func fetchConfig() {
        
    }
    
    func configureStorage() {
        
    }
    
}
