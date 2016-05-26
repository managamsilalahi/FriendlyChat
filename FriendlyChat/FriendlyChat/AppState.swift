//
//  AppState.swift
//  FriendlyChat
//
//  Created by Admin on 5/26/16.
//  Copyright © 2016 Managam. All rights reserved.
//

import Foundation

class AppState: NSObject {
    
    static let sharedInstance = AppState()
    
    var signedIn = false
    var displayName: String?
    var photoUrl: NSURL?
    
}
