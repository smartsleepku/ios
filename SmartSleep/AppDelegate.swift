//
//  AppDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let sleepStatusService = SleepStatusService()
    let attendeeService = AttendeeService()
    let heartbeatService = HeartbeatService()
    private let activityService = ActivityService()
    private let authService = AuthenticationService()
    let audioService = AudioService()
    let locationService = LocationService()
    let restService = RestService()
    let nightService = NightService()
    private let credentialsService = CredentialsService()
    private let bag = DisposeBag()

    let activityUpdates = PublishSubject<ActivityProgressUpdate>()
    let sleepUpdates = PublishSubject<SleepProgressUpdate>()
    let heartbeatUpdates = PublishSubject<HeartbeatProgressUpdate>()
    let tonight = PublishSubject<Night>()

    private var heartbeatStarted = false

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.setMinimumBackgroundFetchInterval(3600)
        started()
        attendeeService.configure()
        return true
    }

    func application(_ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                NSLog("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                self.attendeeService.sync(deviceToken: result.token)
                NSLog("Remote instance ID token: \(result.token)")
            }
        }
    }

    func application(_ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        attendeeService.sync(deviceToken: nil)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        startOperations()
        HeartbeatService.storeHeartbeatUpdate()
        HeartbeatService.backgroundSync()
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        NSLog("handleEventsForBackgroundURLSession: \(identifier)")
        startOperations()
        completionHandler()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // HeartbeatService.backgroundSync()
        completionHandler(.newData)
    }

    func synchronizeSleep() {
        sleepStatusService.fetchStatus { hasLocation in
            if hasLocation == true {
                self.sleepStatusService.sync()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { update in
                        self.sleepUpdates.on(.next(update))
                        }, onCompleted: {
                            self.generateNights()
                    }).disposed(by: self.bag)
            }
        }
        activityService.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] update in
                self?.activityUpdates.on(.next(update))
            }).disposed(by: self.bag)
        heartbeatService.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { update in
                self.heartbeatUpdates.on(.next(update))
            }).disposed(by: self.bag)
        if !heartbeatStarted {
            // set heartbeat interval to 5 minutes
            // HeartbeatService.storeHeartbeatUpdate()
            // Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: {_ in
            //     HeartbeatService.storeHeartbeatUpdate()
            // })
            heartbeatStarted = true
        }
    }

    func generateNights() {
        nightService.generateNights().andThen(Completable.create { completable in
            defer {
                completable(.completed)
            }
            let tonight = self.nightService.fetchOne(at: Date())
            guard tonight != nil else { return Disposables.create() }
            self.tonight.on(.next(tonight!))
            return Disposables.create()
        }).observeOn(MainScheduler.instance).subscribe().disposed(by: bag)
    }


    func applicationWillTerminate(_ application: UIApplication) {
        ended()
    }

    func ended() {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("Title",
                                                      tableName: "AppDelegate",
                                                      bundle: .main,
                                                      value: "SmartSleep afbrudt",
                                                      comment: "")
        notificationContent.body = NSLocalizedString("Body",
                                                     tableName: "AppDelegate",
                                                     bundle: .main,
                                                     value: "SmartSleep skal køre i baggrunden for at kunne måle søvnrytmer. Start SmartSleep inden du går i seng.",
                                                     comment: "")
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let notificationRequest = UNNotificationRequest(identifier: "dk.ku.sund.SmartSleep.app.interrupted",
                                                        content: notificationContent,
                                                        trigger: notificationTrigger)
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                NSLog("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }

    func started() {
        FirebaseApp.configure()
        let nc = UNUserNotificationCenter.current()
        nc.removePendingNotificationRequests(withIdentifiers: ["dk.ku.sund.SmartSleep.app.interrupted"])
        nc.removeDeliveredNotifications(withIdentifiers: ["dk.ku.sund.SmartSleep.app.interrupted"])
    }

    func synchronizeToken() {
        let ud = UserDefaults()
        let credentialsManager = CredentialsService()
        guard credentialsManager.credentials != nil else { return }
        guard let code: String = ud.valueFor(.attendeeCode) else { return }
        authService.postCredentials(toAttendee: code)
    }

    func startOperations() {
        synchronizeToken()
        synchronizeSleep()
        let ud = UserDefaults()
        if (ud.valueFor(.paused) ?? false) == false {
            audioService.startRecording()
            locationService.start()
        }
        sleepStatusService.fetchStatus { hasLocation in
            guard hasLocation else { return }
            SleepStatusHelper().registerAppforSleepStatus()
        }
    }
}
