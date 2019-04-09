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

    let attendeeService = AttendeeService()
    private let activityService = ActivityService()
    private let restService = RestService()
    let nightService = NightService()
    private let credentialsService = CredentialsService()
    private let bag = DisposeBag()

    let activityUpdates = PublishSubject<ActivityProgressUpdate>()
    let restUpdates = PublishSubject<RestProgressUpdate>()
    let tonight = PublishSubject<Night>()
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        attendeeService.configure()
        return true
    }

    func application(_ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                self.attendeeService.sync(deviceToken: result.token)
                print("Remote instance ID token: \(result.token)")
            }
        }
    }
    
    func application(_ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        attendeeService.sync(deviceToken: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        synchronizeActivities()
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession: \(identifier)")
        completionHandler()
    }
    
    func synchronizeActivities() {
        activityService.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] update in
                self?.activityUpdates.on(.next(update))
                }, onCompleted: { [weak self] in
                    self?.synchronizeRest()
            }).disposed(by: bag)
    }
    
    func synchronizeRest() {
        restService.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] rest in
                self?.restUpdates.on(.next(RestProgressUpdate(
                    rest: rest,
                    done: false
                )))
            }, onCompleted: { [weak self] in
                self?.restUpdates.on(.next(RestProgressUpdate(
                    rest: nil,
                    done: true
                )))
                self?.generateNights()
        }).disposed(by: bag)
    }
    
    func generateNights() {
        nightService.generateNights().andThen(Completable.create { completable in
            defer {
                completable(.completed)
            }
            let tonight = self.nightService.fetchOne(at: Date(timeIntervalSinceNow: -24 * 60 * 60))
            guard tonight != nil else { return Disposables.create() }
            self.tonight.on(.next(tonight!))
            return Disposables.create()
        }).subscribe().disposed(by: bag)
    }
    
}

