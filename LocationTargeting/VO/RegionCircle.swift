//
//  RegionCircle.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import MapKit

class RegionCircle {
    let circle: MKCircle
    var color: UIColor
    
    public required init(color: UIColor, center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.color = color
        self.circle = MKCircle(center: center, radius: radius)
    }
}
