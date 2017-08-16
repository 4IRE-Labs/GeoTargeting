//
//  MapViewDataStore.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 16.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import CoreLocation

protocol MapViewDataStoreProtocol {
    func fetchRegions() -> [CLCircularRegion]
    func saveOnEnterTo(region: CLCircularRegion)
    func removeAfterExit(region: CLCircularRegion)
    func visitableRegion(for region: CLCircularRegion) -> VisitableRegion?
    func saveAsNotified(visitableRegion: VisitableRegion)
}

class MapViewDataStore {
    typealias Identifier = String
    
    var visitingRegions: [Identifier: VisitableRegion] = [:]
    lazy var regions: [CLCircularRegion] = self.generateRegions()
    
    private func generateRegions() -> [CLCircularRegion] {
        let regions: [(coord: CLLocationCoordinate2D, radius: CLLocationDistance,
            name: String)] = [
            (CLLocationCoordinate2DMake(50.476078, 30.497851), 300, "Location 0"),
            (CLLocationCoordinate2DMake(50.486074, 30.497860), 120, "Location 1"),
            (CLLocationCoordinate2DMake(50.486074, 30.497860), 59, "Location 2"),
            (CLLocationCoordinate2DMake(50.486684, 30.491860), 340, "Location 3"),
            (CLLocationCoordinate2DMake(50.486085, 30.495857), 293, "Location 4"),
            (CLLocationCoordinate2DMake(50.486085, 30.498857), 89, "Location 5"),
            (CLLocationCoordinate2DMake(50.4631324, 30.4916244), 100, "Seductive")
        ]
        return regions.map {
            CLCircularRegion(center: $0, radius: $1, identifier: $2)
        }
    }
    
    /* It is just moced data, it can be implemented in future */
    func minTimeToCheckin(in region: CLCircularRegion) -> TimeInterval {
        return 500
    }
}

extension MapViewDataStore: MapViewDataStoreProtocol {
    func removeAfterExit(region: CLCircularRegion) {
        visitingRegions[region.identifier] = nil
    }

    func saveAsNotified(visitableRegion: VisitableRegion) {
        var visitableRegion = visitableRegion
        visitableRegion.isNotified = true
        visitingRegions[visitableRegion.region.identifier] = visitableRegion
    }

    func visitableRegion(for region: CLCircularRegion) -> VisitableRegion? {
        return visitingRegions[region.identifier]
    }

    func saveOnEnterTo(region: CLCircularRegion) {
        guard visitingRegions[region.identifier] == nil else {
            print("Region alredy visited")
            return
        }
        let visitableRegion = VisitableRegion(region: region, entered: Date(),
                                              minTimeToCheckin: minTimeToCheckin(in: region))
        visitingRegions[region.identifier] = visitableRegion
    }

    func fetchRegions() -> [CLCircularRegion] {
        return regions
    }
}
