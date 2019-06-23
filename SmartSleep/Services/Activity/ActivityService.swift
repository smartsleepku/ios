//
//  ActivityService.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import CoreMotion
import RxSwift

fileprivate extension URLSessionTask {
    private struct Property {
        static var activities = [String: Activity]()
        static let lock = NSLock()
    }
    var activity: Activity? {
        get {
            Property.lock.lock()
            defer { Property.lock.unlock() }
            return Property.activities[self.debugDescription]
        }
        set(value) {
            Property.lock.lock()
            Property.activities[self.debugDescription] = value
            Property.lock.unlock()
        }
    }
}

fileprivate class Delegate: NSObject, URLSessionTaskDelegate {
    
    weak var completion: CompletionHandler?
    weak var queue: OperationQueue?
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let time = task.activity?.time.timeIntervalSinceReferenceDate,
            let tmp = try? FileManager.default.url(for: .cachesDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: nil,
                                                         create: true)
                .appendingPathComponent("\(time).json") {
            try? FileManager.default.removeItem(at: tmp)
        }
        defer {
            queue?.addOperation { [weak self] in
                self?.completion?.count -= 1
            }
        }
        guard error == nil else { return }
        guard task.response != nil else { return }
        guard (task.response as! HTTPURLResponse).statusCode == 200 else { return }
        let ud = UserDefaults()
        let lastSync: Date = ud.valueFor(.lastActivitySync) ?? Date(timeIntervalSinceNow: -24 * 60 * 60)
        guard let activity = task.activity else { return }

        queue?.addOperation { [weak self] in
            let update = ActivityProgressUpdate(
                activity: activity,
                remaining: (self?.completion?.count ?? 1) - 1
            )
            DispatchQueue.main.sync {
                self?.completion?
                    .subject?
                    .on(.next(update))
            }
        }

        guard activity.time > lastSync else { return }
        ud.setValueFor(.lastActivitySync, to: activity.time.addingTimeInterval(1))
        ud.synchronize()
    }
}

fileprivate class CompletionHandler {
    var count = -1 {
        didSet {
            if count == 0 {
                let subject = self.subject
                DispatchQueue.main.async {
                    subject?.on(.completed)
                }
                endBackgroundTask()
            }
        }
    }
    
    var subject: PublishSubject<ActivityProgressUpdate>?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let task = self?.backgroundTask else { return }
            guard task != .invalid else { return }
            UIApplication.shared.endBackgroundTask(task)
            self?.backgroundTask = .invalid
        }
    }
    
    func endBackgroundTask() {
        current = nil
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
}

fileprivate var current: CompletionHandler? = nil

class ActivityService {
    
    private let queue = OperationQueue()
    private let manager = CMMotionActivityManager()
    private lazy var session: URLSession = {
        var configuration = URLSessionConfiguration.background(withIdentifier: "com.cyborch.dk.ku.smartsleep.activity")
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        let delegate = Delegate()
        delegate.queue = self.queue
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: OperationQueue.current)
    }()
    
    
    func sync() -> Observable<ActivityProgressUpdate> {
        guard TokenService().token != nil else { return Observable.empty() }
        guard CMMotionActivityManager.isActivityAvailable() else { return Observable.empty() }
        guard current == nil else { return current!.subject! }

        let observable = PublishSubject<ActivityProgressUpdate>()

        let completionHandler = CompletionHandler()
        completionHandler.subject = observable
        completionHandler.beginBackgroundTask()
        (session.delegate as! Delegate).completion = completionHandler
        current = completionHandler
        
        let handler: CMMotionActivityQueryHandler = { activities, error in
            guard error == nil else { NSLog("\(error!)") ; return }
            
            completionHandler.count = activities?.count ?? 0
            
            activities?.forEach({ activity in
                
                let confidence: Int
                switch activity.confidence {
                case .low:
                    confidence = 25
                case .medium:
                    confidence = 50
                case .high:
                    confidence = 75
                }
                
                let type: String
                if activity.automotive { type = "automotive" }
                else if activity.cycling { type = "cycling" }
                else if activity.running { type = "running" }
                else if activity.stationary { type = "stationary" }
                else if activity.walking { type = "walking" }
                else { type = "unknown" }
                
                let event = Activity(
                    type: type,
                    confidence: confidence,
                    time: activity.startDate
                )
                
                self.postActivity(event, completion: completionHandler)
                
                NSLog("\(activity.startDate) - stationary: \(activity.stationary), confidence: \(activity.confidence.rawValue)")
            })
        }
        
        let ud = UserDefaults()
        let lastSync = ud.valueFor(.lastActivitySync) ?? Date(timeIntervalSinceNow: -24 * 60 * 60)
        manager.queryActivityStarting(from: lastSync,
                                      to: Date(),
                                      to: queue,
                                      withHandler: handler)
        
        return observable
    }
    
    private func postActivity(_ activity: Activity, completion: CompletionHandler) {
        let url = URL(string: baseUrl + "/activity")!
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 500)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let json = try encoder.encode(activity)
            let tmp = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
                .appendingPathComponent("\(activity.time.timeIntervalSinceReferenceDate).json")
            try json.write(to: tmp)
            guard FileManager.default.fileExists(atPath: tmp.absoluteString.replacingOccurrences(of: "file://", with: "")) else {
                NSLog("missing file: \(tmp)")
                return
            }
            let task = session.uploadTask(with: request, fromFile: tmp)
            task.activity = activity
            task.resume()
        } catch let error {
            NSLog("\(error)")
            queue.addOperation {
                completion.count -= 1
            }
        }
    }
}

