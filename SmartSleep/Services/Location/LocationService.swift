//
//  LocationService.swift
//  SmartSleep
//
//  Created by Anders Borch on 14/05/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import CoreLocation

class LocationService {
    let delegate = LocationDelegate()

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = delegate
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        return manager
    }()

    func start() {
        locationManager.startUpdatingLocation()
    }

    func verifyAuthorization(controller: UIViewController) {
        delegate.callback = { granted in
            guard granted == false else { return }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: NSLocalizedString("Title",
                                                                       tableName: "LocationService",
                                                                       bundle: .main,
                                                                       value: "Lokation",
                                                                       comment: ""),
                                              message: NSLocalizedString("Body",
                                                                         tableName: "LocationService",
                                                                         bundle: .main,
                                                                         value: "Lokation er nødvendig for at kunne måle søvnrytmer. " +
                                                                            "Giv tilladelse til altid at bruge lokation i Indstillinger.",
                                                                         comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                              style: .default,
                                              handler: { action in
                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                          options: [:],
                                                                          completionHandler: nil)
                }))
                controller.present(alert, animated: true, completion: nil)
            }
        }
        delegate.locationManager(locationManager, didChangeAuthorization: CLLocationManager.authorizationStatus())
        locationManager.requestAlwaysAuthorization()
    }
}
