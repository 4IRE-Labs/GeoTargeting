//
//  MapViewInteractor.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications

protocol MapViewInteractorOutput: class {
    func onChangedUserTemp(region: CLCircularRegion?)
    func monitorable(regions: [CLCircularRegion], unmonitorable: [CLCircularRegion])
    
    func onExit(visitableRegion: VisitableRegion)
    func onEnter(visitableRegion: VisitableRegion)
    
    func performSystemCantTrackRegions()
    func performUserLocationNotAuthorized()
    func onUserNotificationAuthorization(error: Error)
}

protocol MapViewInteractorProtocol {
    var output: MapViewInteractorOutput! { get }
    var dataStore: MapViewDataStoreProtocol { get }
    
    func requestLocationAuthorization() -> Void
    func requestNotificationAuthorization() -> Void
}

class MapViewInteractor: NSObject {
    typealias RegionsTuple = (monitorable: [CLCircularRegion], unmonitorable: [CLCircularRegion])
    
    weak var output: MapViewInteractorOutput!
    var dataStore: MapViewDataStoreProtocol
    
    /* It is region from user to 10's nearest region after sortion */
    private(set) var userTempRegion: CLCircularRegion? {
        willSet {
            stopMonitoringUserTempRegion()
        }
        didSet {
            startMonitoringUserTempRegion()
        }
    }
    fileprivate(set) var regionsToMonitore: [CLCircularRegion] = [] {
        willSet {
            stopMonitoringRegions()
        }
        didSet {
            startMonitoringRegions()
        }
    }
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .fitness
        manager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        manager.desiredAccuracy = kCLLocationAccuracyBest;
        manager.delegate = self;
        return manager
    }()
    
    static let TEMP_REGION_IDENTIFIER = "USER_TEMP_REGION_IDENTIFIER"
    /* Max can be 19 */
    static let MAX_REGIONS_TO_MONITORE_AT_ONCE = 3
    /* Distance in meters */
    static let MAX_RADIUS_TO_RECALCULATE_MONITORABLE = 3000.0
    
    
    init(dataStore: MapViewDataStoreProtocol) {
        self.dataStore = dataStore
    }
    
    
    //MARK: - Monitoring
    
    fileprivate func startMonitoringRegions() -> Void {
        regionsToMonitore.forEach { region in
            locationManager.startMonitoring(for: region)
        }
    }
    
    fileprivate func stopMonitoringRegions() -> Void {
        regionsToMonitore.forEach { region in
            locationManager.stopMonitoring(for: region)
        }
    }
    
    fileprivate func startMonitoringUserTempRegion() -> Void {
        guard let userTempRegion = userTempRegion else {
            return
        }
        locationManager.startMonitoring(for: userTempRegion)
    }
    
    fileprivate func stopMonitoringUserTempRegion() -> Void {
        guard let userTempRegion = userTempRegion else {
            return
        }
        locationManager.stopMonitoring(for: userTempRegion)
    }
    
    fileprivate func isCanSystemMonitoreRegions() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }
    
    fileprivate func isRegionsCalculated() -> Bool {
        return userTempRegion != nil
    }
    
    fileprivate func calculateMonitorable() {
        guard let userLocation = locationManager.location else {
            print("Don't know user location")
            return
        }
        guard isCanSystemMonitoreRegions() else {
            output.performSystemCantTrackRegions()
            return
        }
        let limit = MapViewInteractor.MAX_REGIONS_TO_MONITORE_AT_ONCE
        let regionsTuple = monitorableRegions(for: userLocation, limit: limit)
        regionsToMonitore = regionsTuple.monitorable
        userTempRegion = recalculateUserTempRegion(for: userLocation)
        output.monitorable(regions: regionsToMonitore,
                           unmonitorable: regionsTuple.unmonitorable)
        output.onChangedUserTemp(region: userTempRegion)
    }
    
    func monitorableRegions(for userLocation: CLLocation, limit: Int) -> RegionsTuple {
        let allRegions = dataStore.fetchRegions()
        let sortedRegions = allRegions.sorted(by: {
            sortNearest(region1: $0, region2: $1, userLocation: userLocation)
        })
        let monitoreable = Array(sortedRegions.prefix(limit))
        let unmonitoreable = Array(sortedRegions.suffix(from: limit))
        return (monitoreable, unmonitoreable)
    }
    
    private func sortNearest(region1: CLCircularRegion, region2: CLCircularRegion,
                             userLocation: CLLocation) -> Bool {
        let distance1 = userLocation.distance(from: region1.toCLLocation()) - region1.radius
        let distance2 = userLocation.distance(from: region2.toCLLocation()) - region2.radius
        return distance1 < distance2
    }
    
    fileprivate func recalculateUserTempRegion(for userLocation: CLLocation) -> CLCircularRegion? {
        guard let index = regionsToMonitore.halfCount else {
            return nil
        }
        let halfRegion = regionsToMonitore[index]
        let center = CLLocationCoordinate2DMake(userLocation.coordinate.latitude,
                                                userLocation.coordinate.longitude)
        let maxRadius = min(MapViewInteractor.MAX_RADIUS_TO_RECALCULATE_MONITORABLE, userLocation.distance(from: halfRegion.toCLLocation()))
        let radius = max(halfRegion.radius, maxRadius)
        let region = CLCircularRegion(center: center,
                                      radius: radius,
                                      identifier: MapViewInteractor.TEMP_REGION_IDENTIFIER)
        return region
    }
    
    //MARK: - Output Enter/Exit
    
    fileprivate func outputIfNeededUserEnter(region: CLCircularRegion) {
        guard let visitableRegion = dataStore.visitableRegion(for: region),
            !visitableRegion.isNotified,
            visitableRegion.canToCheckIn() else {
            return
        }
        dataStore.saveAsNotified(visitableRegion: visitableRegion)
        output.onEnter(visitableRegion: visitableRegion)
    }
    
    fileprivate func outputIfNeededUserExit(region: CLCircularRegion) {
        guard let visitableRegion = dataStore.visitableRegion(for: region) else {
            return
        }
        output.onExit(visitableRegion: visitableRegion)
    }
}


extension MapViewInteractor: MapViewInteractorProtocol {
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound]
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: options) { (granted, error) in
                    if let error = error {
                        self.output.onUserNotificationAuthorization(error: error)
                    }
                }
            } else if settings.authorizationStatus == .denied {
                //TODO: Show user alert that notifications not allowed by user
            }
        }
    }

    func requestLocationAuthorization() -> Void {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .denied {
            output.performUserLocationNotAuthorized()
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

extension MapViewInteractor: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier != MapViewInteractor.TEMP_REGION_IDENTIFIER,
            let circleRegion = region as? CLCircularRegion else {
            return
        }
        dataStore.saveOnEnterTo(region: circleRegion)
        outputIfNeededUserEnter(region: circleRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circleRegion = region as? CLCircularRegion else {
            return
        }
        if region.identifier == MapViewInteractor.TEMP_REGION_IDENTIFIER {
            calculateMonitorable()
        }
        outputIfNeededUserExit(region: circleRegion)
        dataStore.removeAfterExit(region: circleRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isRegionsCalculated() else {
            return
        }
        calculateMonitorable()
    }
}
