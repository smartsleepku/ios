//
//  LocationDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 14/05/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private lazy var audioService: AudioService = {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.audioService
    }()
    
    var callback: ((_ authorized: Bool) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        callback?(status == .authorizedAlways)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("updating location at \(Date())")
        if audioService.recording {
            LocationDelegate.removeNotifications()
        } else {
            LocationDelegate.updatePendingNotification()
        }
        endBackgroundTask()
        beginBackgroundTask()
    }
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let task = self?.backgroundTask else { return }
            guard task != .invalid else { return }
            UIApplication.shared.endBackgroundTask(task)
            self?.backgroundTask = .invalid
        }
    }
    
    func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
    
    static func removeNotifications() {
        let nc = UNUserNotificationCenter.current()
        nc.removePendingNotificationRequests(withIdentifiers: ["dk.ku.sund.SmartSleep.location.interrupted"])
        nc.removeDeliveredNotifications(withIdentifiers: ["dk.ku.sund.SmartSleep.location.interrupted"])
    }
    
    static func updatePendingNotification() {
        removeNotifications()
        let notificationContent = UNMutableNotificationContent()
        let nc = UNUserNotificationCenter.current()
        notificationContent.title = NSLocalizedString("Title",
                                                      tableName: "LocationService",
                                                      bundle: .main,
                                                      value: "SmartSleep afbrudt",
                                                      comment: "")
        notificationContent.body = NSLocalizedString("Body",
                                                     tableName: "LocationService",
                                                     bundle: .main,
                                                     value: "SmartSleep skal køre i baggrunden for at kunne måle søvnrytmer. " +
                                                        "Start SmartSleep inden du går i seng.",
                                                     comment: "")
        notificationContent.sound = .default
        notificationContent.badge = 1
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let notificationRequest = UNNotificationRequest(identifier: "dk.ku.sund.SmartSleep.location.interrupted",
                                                        content: notificationContent,
                                                        trigger: notificationTrigger)
        nc.add(notificationRequest) { (error) in
            if let error = error {
                NSLog("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
}
