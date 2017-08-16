//
//  MapPresenter.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications

protocol MapPresenterProtocol {
    var view: MapViewProtocol { get }
    var router: MapRouterProtocol { get }
    var interactor: MapViewInteractorProtocol { get }
    
    func requestLocationAuthorization() -> Void
    func requestNotificationAuthorization() -> Void
}


class MapViewPresenter {
    unowned let view: MapViewProtocol
    
    let router: MapRouterProtocol
    let interactor: MapViewInteractorProtocol
    
    init(view: MapViewProtocol, router: MapRouterProtocol,
         interactor: MapViewInteractorProtocol) {
        self.view = view
        self.router = router
        self.interactor = interactor
    }
    
    fileprivate func showNotificationUserExit(visitableRegion: VisitableRegion) {
        if visitableRegion.canToCheckIn() {
            let body = "User exit, but spent not enought time to checkin (\(visitableRegion.spentTime())"
            showNotification(body: body, visitableRegion: visitableRegion)
        } else {
            let body = "User exit, but spent not enought time to checkin (\(visitableRegion.spentTime()))"
            showNotification(body: body, visitableRegion: visitableRegion)
        }
    }
    
    fileprivate func showNotificationUserEnter(visitableRegion: VisitableRegion) {
        let body = "User entered and spent enought time to chekin here (\(visitableRegion.spentTime())"
        showNotification(body: body, visitableRegion: visitableRegion)
    }
    
    private func showNotification(body: String, visitableRegion: VisitableRegion) {
        let identifier = visitableRegion.region.identifier
        let content = UNMutableNotificationContent()
        content.title = identifier
        content.body = body
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        router.showNotification(request: request)
    }
}


extension MapViewPresenter: MapPresenterProtocol {
    func requestLocationAuthorization() -> Void {
        interactor.requestLocationAuthorization()
    }
    
    func requestNotificationAuthorization() {
        interactor.requestNotificationAuthorization()
    }
}


extension MapViewPresenter: MapViewInteractorOutput {
    func onUserNotificationAuthorization(error: Error) {
        router.showUserNotAllowedNotifications(error: error)
    }

    func onChangedUserTemp(region: CLCircularRegion?) {
        view.clearUserTempRegionFromMapView()
        if let tempRegion = region {
            let tempAnnotation = tempRegion.toRegionAnnotation(color: .red)
            view.showUserTemp(regionAnnotation: tempAnnotation)
        }
    }
    
    func monitorable(regions: [CLCircularRegion], unmonitorable: [CLCircularRegion]) {
        view.clearRegionsFromMapView()
        regions.map{ $0.toRegionAnnotation() }
            .forEach{ view.show(regionAnnotation: $0) }
        unmonitorable.map{ $0.toRegionAnnotation(color: .gray) }
            .forEach{ view.show(regionAnnotation: $0) }
    }
    
    func onExit(visitableRegion: VisitableRegion) {
        view.onExitRegion(title: visitableRegion.region.identifier)
        showNotificationUserExit(visitableRegion: visitableRegion)
    }
    
    func onEnter(visitableRegion: VisitableRegion) {
        view.onEnterRegion(title: visitableRegion.region.identifier)
        showNotificationUserEnter(visitableRegion: visitableRegion)
    }
    
    func performSystemCantTrackRegions() {
        router.showSystemCantTrackRegions()
    }
    
    func performUserLocationNotAuthorized() {
        router.showUserLocationNotAuthorized()
    }
}
