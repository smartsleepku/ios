//
//  SleepStatusService.swift
//  SmartSleep
//
//  Created by Anders Borch on 14/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import SQLite3
import RxSwift

fileprivate struct HasLocation: Codable {
    var has_location: Bool
}

fileprivate extension URLSessionTask {
    private struct Property {
        static var sleeps = [String: Sleep]()
        static let lock = NSLock()
    }
    var sleep: Sleep? {
        get {
            Property.lock.lock()
            defer { Property.lock.unlock() }
            return Property.sleeps[self.debugDescription]
        }
        set(value) {
            Property.lock.lock()
            Property.sleeps[self.debugDescription] = value
            Property.lock.unlock()
        }
    }
}

fileprivate class Delegate: NSObject, URLSessionTaskDelegate {
    weak var completion: CompletionHandler?
    weak var queue: OperationQueue?
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let time = task.sleep?.time?.timeIntervalSinceReferenceDate,
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
        let lastSync: Date = ud.valueFor(.lastSleepSync) ?? Date(timeIntervalSinceNow: -24 * 60 * 60)
        guard let sleep = task.sleep else { return }
        
        queue?.addOperation { [weak self] in
            self?.completion?.subject?.on(.next(SleepProgressUpdate(
                sleep: sleep,
                remaining: (self?.completion?.count ?? 1) - 1
            )))
        }
        
        guard sleep.time! > lastSync else { return }
        ud.setValueFor(.lastSleepSync, to: sleep.time!.addingTimeInterval(1))
        ud.synchronize()
    }
    
}

fileprivate class CompletionHandler {
    var count = -1 {
        didSet {
            if count == 0 {
                subject?.on(.completed)
                endBackgroundTask()
            }
        }
    }
    
    var subject: PublishSubject<SleepProgressUpdate>?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func beginBackgroundTask() {
        UIApplication.shared.beginBackgroundTask { [weak self] in
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

class SleepStatusService: NSObject {
    
    private let queue = OperationQueue()
    private let delegate = Delegate()
    private lazy var backgroundSession: URLSession = {
        var configuration = URLSessionConfiguration.background(withIdentifier: "com.cyborch.dk.ku.smartsleep.SmartSleep")
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        let delegate = Delegate()
        delegate.queue = self.queue
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: OperationQueue.current)
    }()
    private let foregroundSession = URLSession(configuration: .ephemeral)

    func fetchStatus(completion: @escaping (Bool) -> Void) {
        let task = foregroundSession.dataTask(with: URL(string: baseUrl + "/haslocation")!) { (data, response, error) in
            guard error == nil else { return }
            guard data != nil else { return }
            do {
                let loc = try JSONDecoder().decode(HasLocation.self, from: data!)
                completion(loc.has_location)
            } catch let error {
                print(error)
            }
        }
        task.resume()
    }
    
    @objc static func storeSleepUpdate(_ sleeping: Bool) {
        let db = DatabaseService.instance
        db.queue.async {
            Sleep(id: nil, time: Date(), sleeping: sleeping).save()
        }
    }
    
    func fetch(from: Date, to: Date) -> [Sleep] {
        let service = DatabaseService.instance
        var result = [Sleep]()
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "select * from sleeps where time >= ? and time <= ? order by time asc"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 2, to.timeIntervalSince1970)
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    result.append(Sleep(queryStatement: queryStatement!))
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    func sync() -> Observable<SleepProgressUpdate> {
        guard TokenService().token != nil else { return Observable.empty() }
        guard current == nil else { return current!.subject! }
        
        let observable = PublishSubject<SleepProgressUpdate>()
        
        let completionHandler = CompletionHandler()
        completionHandler.beginBackgroundTask()
        (backgroundSession.delegate as! Delegate).completion = completionHandler
        current = completionHandler
        
        let ud = UserDefaults()
        let lastSync = ud.valueFor(.lastSleepSync) ?? Date(timeIntervalSinceNow: -24 * 60 * 60)
        let sleeps = fetch(from: lastSync, to: Date())
        completionHandler.subject = observable
        completionHandler.count = sleeps.count
        
        sleeps.forEach({ sleep in
            self.postSleep(sleep, completion: completionHandler)
            print("\(sleep.time!) - sleeping: \(sleep.sleeping!)")
        })
        
        return observable
    }
    
    private func postSleep(_ sleep: Sleep, completion: CompletionHandler) {
        let url = URL(string: baseUrl + "/sleep")!
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 500)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let json = try encoder.encode(sleep)
            let tmp = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
                .appendingPathComponent("\(sleep.time!.timeIntervalSinceReferenceDate).json")
            try json.write(to: tmp)
            let task = backgroundSession.uploadTask(with: request, fromFile: tmp)
            task.sleep = sleep
            task.resume()
        } catch let error {
            print(error)
            queue.addOperation {
                completion.count -= 1
            }
        }
    }
}
