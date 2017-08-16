//
//  ViewController.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

protocol MapViewProtocol: class {
    func clearRegionsFromMapView() -> Void
    func clearUserTempRegionFromMapView() -> Void
    func show(regionAnnotation: RegionAnnotation) -> Void
    func showUserTemp(regionAnnotation: RegionAnnotation) -> Void
    func onExitRegion(title: String)
    func onEnterRegion(title: String)
}

class MapViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    
    var presenter: MapPresenterProtocol!
    var annotations: [RegionAnnotation] = []
    var userTempAnnottation: RegionAnnotation?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.requestLocationAuthorization()
        presenter.requestNotificationAuthorization()
    }
}


extension MapViewController: MapViewProtocol {
    func clearRegionsFromMapView() -> Void {
        annotations.forEach {
            mapView.removeRegionAnnotation($0)
        }
        annotations = []
    }
    
    func clearUserTempRegionFromMapView() {
        if let tempAnnotation = userTempAnnottation {
            mapView.removeRegionAnnotation(tempAnnotation)
            userTempAnnottation = nil
        }
    }
    
    func show(regionAnnotation: RegionAnnotation) {
        annotations.append(regionAnnotation)
        mapView.addRegionAnnotation(regionAnnotation)
    }
    
    func showUserTemp(regionAnnotation: RegionAnnotation) {
        userTempAnnottation = regionAnnotation
        mapView.addRegionAnnotation(regionAnnotation)
    }
    
    func onExitRegion(title: String) {
        textView.text = textView.text!.appending("\n User Exit \(title) region")
    }
    
    func onEnterRegion(title: String) {
        textView.text = textView.text!.appending("\n User Enter \(title) region")
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlayCircle = overlay as? MKCircle  {
            return configure(circle: overlayCircle)
        }
        return MKCircleRenderer(overlay: overlay)
    }
    
    private func configure(circle: MKCircle) -> MKCircleRenderer {
        let circleRenderer = MKCircleRenderer(overlay: circle)
        if let annotation = userTempAnnottation, circle == annotation.regionCircle.circle {
            circleRenderer.strokeColor = annotation.regionCircle.color
        } else if let annotation = annotations.first(where: { $0.regionCircle.circle == circle }) {
            circleRenderer.strokeColor = annotation.regionCircle.color
        }
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
}
