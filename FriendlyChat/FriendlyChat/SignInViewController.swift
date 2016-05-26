//
//  ViewController.swift
//  FriendlyChat
//
//  Created by Admin on 5/25/16.
//  Copyright © 2016 Managam. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewWillAppear(animated: Bool) {
        if let user = FIRAuth.auth()?.currentUser {
            self.signedIn(user)
        }
        
        self.emailField.text = self.emailField.text
        self.passwordField.text = self.passwordField.text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Signed In
    func signedIn(user: FIRUser?) {
        MeasurementHelper.sendLoginEvent()
        
        AppState.sharedInstance.displayName = user?.displayName ?? user?.email
        AppState.sharedInstance.photoUrl = user?.photoURL
        AppState.sharedInstance.signedIn = true
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.SignedIn, object: nil, userInfo: nil)
        performSegueWithIdentifier(Constants.Segues.SignInToFp, sender: nil)
    }
    
    // MARK: Sign In
    @IBAction func didTapSignIn(sender: UIButton) {
        // Sign in with credentials
        let email = emailField.text
        let password = passwordField.text
        
        FIRAuth.auth()?.signInWithEmail(email!, password: password!, completion: { (user, error) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.signedIn(user!)
            
        })
    }
    
    // MARK: Sign Up
    @IBAction func didTapSignUp(sender: UIButton) {
        let email = emailField.text
        let password = passwordField.text
        FIRAuth.auth()?.createUserWithEmail(email!, password: password!) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.setDisplayName(user!)
        }
    }
    
    // MARK: Set Display Name
    func setDisplayName(user: FIRUser) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = user.email?.componentsSeparatedByString("@")[0]
        changeRequest.commitChangesWithCompletion { (error) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.signedIn(FIRAuth.auth()?.currentUser)
        }
    }
    
    // MARK: Forgot Password
    @IBAction func didRequestPasswordReset(sender: UIButton) {
        let prompt = UIAlertController.init(title: nil, message: "Email:", preferredStyle: .Alert)
        let okAction = UIAlertAction.init(title: "OK", style: .Default) { (action) in
            
            let userInput = prompt.textFields![0].text
            if ((userInput?.isEmpty) != nil) {
                return
            }
            FIRAuth.auth()?.sendPasswordResetWithEmail(userInput!, completion: { (error) in
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            })
        }
        
        prompt.addTextFieldWithConfigurationHandler(nil)
        prompt.addAction(okAction)
        presentViewController(prompt, animated: true, completion: nil)
        
    }


}

