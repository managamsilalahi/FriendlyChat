//
//  FCViewController.swift
//  FriendlyChat
//
//  Created by Admin on 5/26/16.
//  Copyright © 2016 Managam. All rights reserved.
//

import UIKit
import Firebase

class FCViewController: UIViewController {

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
}
