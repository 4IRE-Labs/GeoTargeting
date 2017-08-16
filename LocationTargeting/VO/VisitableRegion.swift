//
//  VisitableRegion.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 16.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import CoreLocation

struct VisitableRegion {
    let region: CLCircularRegion
    let entered: Date
    let minTimeToCheckin: TimeInterval
    var isNotified: Bool = false
    
    init(region: CLCircularRegion, entered: Date,
         minTimeToCheckin: TimeInterval, isNotified: Bool = false) {
        self.region = region
        self.entered = entered
        self.minTimeToCheckin = minTimeToCheckin
        self.isNotified = isNotified
    }
    
    func canToCheckIn() -> Bool {
        return entered.addingTimeInterval(minTimeToCheckin).compare(Date()) == .orderedAscending
    }
    
    func spentTime() -> TimeInterval {
        return Date().timeIntervalSince(entered)
    }
}
