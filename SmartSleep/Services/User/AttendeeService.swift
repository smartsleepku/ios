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

fileprivate let baseUrl = "https://smartsleep.cyborch.com"

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
    var devices = [Device]()
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    weak var service: AttendeeService?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("willPresent: \(notification.request.content)")
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("didReceive: \(response.actionIdentifier)")
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
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = delegate
        Messaging.messaging().delegate = delegate
        InstanceID.instanceID().instanceID { [weak self] (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                self?.sync(deviceToken: result.token)
            }
        }
    }
    
    static func registerForPushNotifications() {
        var options: UNAuthorizationOptions = [.alert, .badge]
        if #available(iOS 12.0, *) {
            options.formUnion(UNAuthorizationOptions.provisional)
        }
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) {
                granted, error in
                print("Permission granted: \(granted)")
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
}
