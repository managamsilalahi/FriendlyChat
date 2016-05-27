//
//  MeasurementHelper.swift
//  FriendlyChat
//
//  Created by Admin on 5/26/16.
//  Copyright © 2016 Managam. All rights reserved.
//

import Firebase

class MeasurementHelper: NSObject {
    
    static func sendLoginEvent() {
        FIRAnalytics.logEventWithName(kFIREventLogin, parameters: nil)
    }
    
    static func sendLogoutEvent() {
        FIRAnalytics.logEventWithName("logout", parameters: nil)
    }
    
    static func sendMessageEvent() {
        FIRAnalytics.logEventWithName("message", parameters: nil)
    }
    
}
