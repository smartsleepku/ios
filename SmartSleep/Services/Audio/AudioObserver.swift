//
//  AudioObserver.swift
//  SmartSleep
//
//  Created by Anders Borch on 25/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import AVFoundation
import UserNotifications
import RxSwift

class AudioObserver: NSObject {

    weak var session: AVCaptureSession?
    
    let running = PublishSubject<Bool>()
    
    @objc func ended() {
        var notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("InterruptTitle",
                                                      tableName: "AudioNotification",
                                                      bundle: .main,
                                                      value: "Støjmåler afbrudt",
                                                      comment: "")
        notificationContent.body = NSLocalizedString("InterruptBody",
                                                     tableName: "AudioNotification",
                                                     bundle: .main,
                                                     value: "Husk at aktivere din SmartSleep app igen inden du går i seng.",
                                                     comment: "")
        notificationContent.badge = 1
        var notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        var notificationRequest = UNNotificationRequest(identifier: "dk.ku.sund.SmartSleep.audio.interrupted",
                                                        content: notificationContent,
                                                        trigger: notificationTrigger)
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                NSLog("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }

        notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("SleepTitle",
                                                      tableName: "AudioNotification",
                                                      bundle: .main,
                                                      value: "Sov godt",
                                                      comment: "")
        notificationContent.body = NSLocalizedString("SleepBody",
                                                     tableName: "AudioNotification",
                                                     bundle: .main,
                                                     value: "Husk at aktivere din SmartSleep app før du går i seng.",
                                                     comment: "")
        notificationContent.sound = .default
        notificationContent.badge = 1
        let configuration = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        let (start, _) = NightService.nightThresholds(of: Date(), config: configuration)
        var time = start.timeIntervalSinceNow
        while time < 0 { time += 24 * 60 * 60 }
        notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
        notificationRequest = UNNotificationRequest(identifier: "dk.ku.sund.SmartSleep.audio.gotosleep",
                                                        content: notificationContent,
                                                        trigger: notificationTrigger)
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                NSLog("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }

        running.on(.next(false))
    }
    
    static func removeNotifications() {
        let nc = UNUserNotificationCenter.current()
        nc.removePendingNotificationRequests(withIdentifiers: ["dk.ku.sund.SmartSleep.audio.interrupted"])
        nc.removeDeliveredNotifications(withIdentifiers: ["dk.ku.sund.SmartSleep.audio.interrupted"])
        nc.removePendingNotificationRequests(withIdentifiers: ["dk.ku.sund.SmartSleep.audio.gotosleep"])
        nc.removeDeliveredNotifications(withIdentifiers: ["dk.ku.sund.SmartSleep.audio.gotosleep"])
        LocationDelegate.removeNotifications()
    }
    
    @objc func started() {
        AudioObserver.removeNotifications()
        running.on(.next(true))
    }
    
    @objc func uninterrupt() {
        session?.startRunning()
    }
    
    override init() {
        super.init()
        
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(ended),
                       name: NSNotification.Name.AVCaptureSessionRuntimeError,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(ended),
                       name: NSNotification.Name.AVCaptureSessionDidStopRunning,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(ended),
                       name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(uninterrupt),
                       name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(started),
                       name: NSNotification.Name.AVCaptureSessionDidStartRunning,
                       object: nil)
    }
    
    deinit {
        let nc = NotificationCenter.default
        nc.removeObserver(self)
    }
}
