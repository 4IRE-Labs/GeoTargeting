//
//  LocalPushNotificationController.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import UIKit
import UserNotifications

class LocalPushNotificationsController {
    
    func name() -> Void {
        // Swift
        let content = UNMutableNotificationContent()
        content.title = "Don't forget"
        content.body = "Buy some milk"
        content.sound = UNNotificationSound.default()
    }
    
}
