//
//  RegionAnnotation.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import MapKit

class RegionAnnotation: MKPointAnnotation {
    let regionCircle: RegionCircle
    
    init(regionCircle: RegionCircle, coordinate: CLLocationCoordinate2D, title: String) {
        self.regionCircle = regionCircle
        super.init()
        self.coordinate = coordinate
        self.title = title
    }
}
