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
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("Title",
                                                      tableName: "AudioNotification",
                                                      bundle: .main,
                                                      value: "Støjmåler afbrudt",
                                                      comment: "")
        notificationContent.body = NSLocalizedString("Body",
                                                     tableName: "AudioNotification",
                                                     bundle: .main,
                                                     value: "Støjmåleren er nødvendig for at kunne måle søvnrytmer. " +
                                                            "Start støjmåleren i SmartSleep inden du går i seng.",
                                                     comment: "")
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let notificationRequest = UNNotificationRequest(identifier: "dk.ku.sund.SmartSleep.audio.interrupted",
                                                        content: notificationContent,
                                                        trigger: notificationTrigger)
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
        running.on(.next(false))
    }
    
    @objc func started() {
        let nc = UNUserNotificationCenter.current()
        nc.removePendingNotificationRequests(withIdentifiers: ["dk.ku.sund.SmartSleep.audio.interrupted"])
        nc.removeDeliveredNotifications(withIdentifiers: ["dk.ku.sund.SmartSleep.audio.interrupted"])
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
