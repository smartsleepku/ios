//
//  AttendeeService.swift
//  SmartSleep
//
//  Created by Anders Borch on 04/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase

struct Device: Codable {
    var deviceId: String?
    var deviceType: String?
}

struct Attendee: Codable {
    var id: String?
    var gmtOffset: Int?
    var weekdayMorning: Date?
    var weekdayEvening: Date?
    var weekendMorning: Date?
    var weekendEvening: Date?
    var nextPush: Date?
    var devices = [Device]()
}

struct Debug: Codable {
    var id: String?
    var time: Date?
    var model: String?
    var manufacturer: String?
    var systemVersion: String?
    var systemName: String?
}

fileprivate class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    weak var service: AttendeeService?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("willPresent: \(notification.request.content)")
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("didReceive: \(response.actionIdentifier)")
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.sleepStatusService.fetchStatus { hasLocation in
            guard hasLocation else { return }
            SleepStatusHelper().registerAppforSleepStatus()
        }
        delegate.audioService.startRecording()
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        service?.sync(deviceToken: fcmToken)
    }
}

class AttendeeService {
    
    private let session = URLSession(configuration: .ephemeral)
    private let delegate = NotificationDelegate()
    
    func configure() {
        UNUserNotificationCenter.current().delegate = delegate
        Messaging.messaging().delegate = delegate
        InstanceID.instanceID().instanceID { [weak self] (result, error) in
            if let error = error {
                NSLog("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                NSLog("Remote instance ID token: \(result.token)")
                self?.sync(deviceToken: result.token)
            }
        }
    }
    
    static func registerForPushNotifications(controller: UIViewController) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) {
                granted, error in
                NSLog("Permission granted: \(granted)")
                guard granted else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
        }
    }
    
    func sync(deviceToken: String?) {
        let url = URL(string: baseUrl + "/attendee")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
        
        let offset = TimeZone.current.secondsFromGMT()
        let config = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        
        let attendee = Attendee(
            id: nil,
            gmtOffset: offset / 60,
            weekdayMorning: config.weekdayMorning,
            weekdayEvening: config.weekdayEvening,
            weekendMorning: config.weekendMorning,
            weekendEvening: config.weekendEvening,
            nextPush: Date(),
            devices: [Device(
                deviceId: deviceToken,
                deviceType: "ios"
            )]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let json = try? encoder.encode(attendee) else { return }
        let task = session.uploadTask(with: request, from: json)
        task.resume()
    }
    
    func postDebugInfo() {
        let url = URL(string: baseUrl + "/debug")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelName = String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        let debug = Debug(
            id: nil,
            time: Date(),
            model: modelName,
            manufacturer: "Apple",
            systemVersion: UIDevice.current.systemVersion,
            systemName: UIDevice.current.systemName
        )
        guard let json = try? encoder.encode(debug) else { return }
        let task = session.uploadTask(with: request, from: json)
        task.resume()
    }
}
