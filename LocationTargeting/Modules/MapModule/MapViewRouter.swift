//
//  MapViewControllerRouter.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

protocol MapRouterProtocol: class {
    var view: UIViewController { get }
    
    func showUserLocationNotAuthorized() -> Void
    func showSystemCantTrackRegions()
    func showUserNotAllowedNotifications(error: Error)
    
    func showNotification(request: UNNotificationRequest)
}


class MapViewRouter {
    unowned let view: UIViewController
    
    static func assembleModule() -> UIViewController {
        let view: MapViewController = UIStoryboard.main.instatiate()
        let router = MapViewRouter(view: view)
        let dataStore = MapViewDataStore()
        let interactor = MapViewInteractor(dataStore: dataStore)
        let presenter = MapViewPresenter(view: view, router: router, interactor: interactor)
        
        view.presenter = presenter
        interactor.output = presenter
        
        return UINavigationController(rootViewController: view)
    }
    
    init(view: UIViewController) {
        self.view = view
    }
    
    fileprivate func showCantDisplayNotification(with error: Error) {
        let alert = UIAlertController(title: "Can't display Notification",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        view.present(alert, animated: true)
    }
}


extension MapViewRouter: MapRouterProtocol {
    func showNotification(request: UNNotificationRequest) {
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                self.showCantDisplayNotification(with: error)
            }
        })
    }

    func showUserLocationNotAuthorized() -> Void {
        let alert = UIAlertController(title: "Location not available",
                                      message: "Location services were previously denied. Please enable location services for this app in Settings.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        view.present(alert, animated: true)
    }
    
    func showSystemCantTrackRegions() -> Void {
        let alert = UIAlertController(title: "Location not available",
                                      message: "Your device not support location tracking or you disabled app refresh in background.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        view.present(alert, animated: true)
    }
    
    func showUserNotAllowedNotifications(error: Error) {
        let alert = UIAlertController(title: "Notifications not allowed",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        view.present(alert, animated: true)
    }
}
