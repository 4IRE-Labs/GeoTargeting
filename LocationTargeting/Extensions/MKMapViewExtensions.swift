//
//  MKMapViewExtensions.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
    func addRegionAnnotation(_ annotation: RegionAnnotation) {
        addAnnotation(annotation)
        add(annotation.regionCircle.circle)
    }
    
    func removeRegionAnnotation(_ annotation: RegionAnnotation) {
        removeAnnotation(annotation)
        remove(annotation.regionCircle.circle)
    }
}

