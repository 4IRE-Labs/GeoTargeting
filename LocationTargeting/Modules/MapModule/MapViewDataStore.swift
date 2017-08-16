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
    func enteredToRegions() -> [VisitableRegion]
    
    func nearestRegionByRadius(for userLocation: CLLocation) -> CLCircularRegion?
    func nearestRegionByCenterCoord(for userLocation: CLLocation) -> CLCircularRegion?
    func nearestRegionsByRadius(for userLocation: CLLocation) -> [CLCircularRegion]
    func nearestRegionsByCenterCoord(for userLocation: CLLocation) -> [CLCircularRegion]
}

class MapViewDataStore {
    typealias Identifier = String
    typealias SortFunc = (_ region1: CLCircularRegion, _ region2: CLCircularRegion,
        _ userLocation: CLLocation) -> Bool
    
    var enteredRegions: [Identifier: VisitableRegion] = [:]
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
        return 0
    }
    
    fileprivate func sortNearestByRadius(region1: CLCircularRegion, region2: CLCircularRegion,
                                     userLocation: CLLocation) -> Bool {
        let distance1 = userLocation.distance(from: region1.toCLLocation()) - region1.radius
        let distance2 = userLocation.distance(from: region2.toCLLocation()) - region2.radius
        return abs(distance1) < abs(distance2)
    }
    
    fileprivate func sortNearest(region1: CLCircularRegion, region2: CLCircularRegion,
                             userLocation: CLLocation) -> Bool {
        let distance1 = userLocation.distance(from: region1.toCLLocation()) - region1.radius
        let distance2 = userLocation.distance(from: region2.toCLLocation()) - region2.radius
        return distance1 < distance2
    }
    
    fileprivate func nearestRegions(for userLocation: CLLocation, sortFunc: @escaping SortFunc) -> [CLCircularRegion] {
        let allRegions = fetchRegions()
        let sortedRegions = allRegions.sorted(by: {
            sortFunc($0, $1, userLocation)
        })
        return sortedRegions
    }
}

extension MapViewDataStore: MapViewDataStoreProtocol {
    func enteredToRegions() -> [VisitableRegion] {
        return enteredRegions.map({ $1 })
    }

    func removeAfterExit(region: CLCircularRegion) {
        enteredRegions[region.identifier] = nil
    }

    func saveAsNotified(visitableRegion: VisitableRegion) {
        var visitableRegion = visitableRegion
        visitableRegion.isNotified = true
        enteredRegions[visitableRegion.region.identifier] = visitableRegion
    }

    func visitableRegion(for region: CLCircularRegion) -> VisitableRegion? {
        return enteredRegions[region.identifier]
    }

    func saveOnEnterTo(region: CLCircularRegion) {
        guard enteredRegions[region.identifier] == nil else {
            print("Region alredy visited")
            return
        }
        let visitableRegion = VisitableRegion(region: region, entered: Date(),
                                              minTimeToCheckin: minTimeToCheckin(in: region))
        enteredRegions[region.identifier] = visitableRegion
    }

    func fetchRegions() -> [CLCircularRegion] {
        return regions
    }
    
    //MARK: - Nearest
    
    func nearestRegionByRadius(for userLocation: CLLocation) -> CLCircularRegion? {
        return nearestRegions(for: userLocation, sortFunc: sortNearestByRadius).first
    }
    
    func nearestRegionByCenterCoord(for userLocation: CLLocation) -> CLCircularRegion? {
        return nearestRegions(for: userLocation, sortFunc: sortNearest).first
    }
    
    func nearestRegionsByRadius(for userLocation: CLLocation) -> [CLCircularRegion] {
        return nearestRegions(for: userLocation, sortFunc: sortNearestByRadius)
    }
    
    func nearestRegionsByCenterCoord(for userLocation: CLLocation) -> [CLCircularRegion] {
        return nearestRegions(for: userLocation, sortFunc: sortNearest)
    }
}
