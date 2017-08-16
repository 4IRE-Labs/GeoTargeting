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
    weak var output: MapViewInteractorOutput!
    var dataStore: MapViewDataStoreProtocol
    
    /* It is redline region from user to nearest region after sortion */
    private(set) var userTempRegion: CLCircularRegion? {
        willSet {
            stopMonitoringUserTempRegion()
        }
        didSet {
            startMonitoringUserTempRegion()
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
    /* Distances in meters */
    static let MAX_RADIUS_TO_RECALCULATE_MONITORABLE = 3000.0
    static let MIN_RADIUS_TO_RECALCULATE_MONITORABLE = 50.0
    
    
    init(dataStore: MapViewDataStoreProtocol) {
        self.dataStore = dataStore
    }
    
    
    //MARK: - Monitoring
    
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
        guard let nearestUserRegion = dataStore.nearestRegionByRadius(for: userLocation) else {
            print("User doesn't have any regions to monitore")
            return
        }
        userTempRegion = recalculateUserTempRegion(depenOn: nearestUserRegion,
                                                   userLocation: userLocation)
        let allRegions = dataStore.fetchRegions()
        output.monitorable(regions: [userTempRegion!],
                           unmonitorable: allRegions)
        output.onChangedUserTemp(region: userTempRegion)
    }
    
    fileprivate func recalculateUserTempRegion(depenOn nearest: CLCircularRegion,
                                               userLocation: CLLocation) -> CLCircularRegion {
        let userCenter = CLLocationCoordinate2DMake(userLocation.coordinate.latitude,
                                                userLocation.coordinate.longitude)
        let distanceToNearestBorder = userLocation.distance(from: nearest.toCLLocation()) - nearest.radius
        let radiusMin = min(MapViewInteractor.MAX_RADIUS_TO_RECALCULATE_MONITORABLE, abs(distanceToNearestBorder))
        let radiusMax = max(MapViewInteractor.MIN_RADIUS_TO_RECALCULATE_MONITORABLE, radiusMin)
        let region = CLCircularRegion(center: userCenter,
                                      radius: radiusMax,
                                      identifier: MapViewInteractor.TEMP_REGION_IDENTIFIER)
        return region
    }
    
    //MARK: - Output Enter/Exit
    
    fileprivate func checkEntersToRegions() {
        guard let userLocation = locationManager.location else {
            print("Don't know user location")
            return
        }
        let sortedNearestRegions = dataStore.nearestRegionsByCenterCoord(for: userLocation)
        for circleRegion in sortedNearestRegions {
            if circleRegion.contains(userLocation.coordinate) {
                dataStore.saveOnEnterTo(region: circleRegion)
                outputIfNeededUserEnter(region: circleRegion)
            } else {
                break
            }
        }
    }
    
    fileprivate func checkExitFromRegions() {
        guard let userLocation = locationManager.location else {
            print("Don't know user location")
            return
        }
        let enteredToRegions = dataStore.enteredToRegions()
        enteredToRegions.forEach { visitableRegion in
            if !visitableRegion.region.contains(userLocation.coordinate) {
                outputIfNeededUserExit(region: visitableRegion.region)
                dataStore.removeAfterExit(region: visitableRegion.region)
            }
        }
    }
    
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
        if region.identifier == MapViewInteractor.TEMP_REGION_IDENTIFIER {
            checkEntersToRegions()
            checkExitFromRegions()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == MapViewInteractor.TEMP_REGION_IDENTIFIER {
            checkEntersToRegions()
            checkExitFromRegions()
            calculateMonitorable()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isRegionsCalculated() else {
            return
        }
        calculateMonitorable()
    }
}
