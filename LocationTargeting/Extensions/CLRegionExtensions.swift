//
//  CLRegionExtensions.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension CLCircularRegion {
    func toRegionAnnotation(color: UIColor = .green) -> RegionAnnotation {
        let circle = RegionCircle(color: color, center: center, radius: radius)
        return RegionAnnotation(regionCircle: circle, coordinate: center, title: identifier)
    }
    
    func toCLLocation() -> CLLocation {
        return CLLocation(latitude: center.latitude, longitude: center.longitude)
    }
}

