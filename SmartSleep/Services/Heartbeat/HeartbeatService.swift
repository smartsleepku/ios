//
//  HeartbeatService.swift
//  SmartSleep
//
//  Created on 11/10/19.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import SQLite3
import RxSwift

fileprivate extension URLSessionTask {
    private struct Property {
        static var heartbeats = [String: Heartbeat]()
        static let lock = NSLock()
    }
    var heartbeat: Heartbeat? {
        get {
            Property.lock.lock()
            defer { Property.lock.unlock() }
            return Property.heartbeats[self.debugDescription]
        }
        set(value) {
            Property.lock.lock()
            Property.heartbeats[self.debugDescription] = value
            Property.lock.unlock()
        }
    }
}

fileprivate class Delegate: NSObject, URLSessionTaskDelegate {
    
    weak var completion: CompletionHandler?
    weak var queue: OperationQueue?
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let time = task.heartbeat?.time?.timeIntervalSinceReferenceDate,
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
        let lastSync: Date = ud.valueFor(.lastHeartbeatSync) ?? Date(timeIntervalSinceNow: -48 * 60 * 60)
        guard let heartbeat = task.heartbeat else { return }
        
        queue?.addOperation { [weak self] in
            self?.completion?.subject?.on(.next(HeartbeatProgressUpdate(
                heartbeat: heartbeat,
                remaining: (self?.completion?.count ?? 1) - 1
            )))
        }
        
        guard heartbeat.time! > lastSync else { return }
        ud.setValueFor(.lastHeartbeatSync, to: heartbeat.time!.addingTimeInterval(1))
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
    
    var subject: PublishSubject<HeartbeatProgressUpdate>?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func beginBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
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

class HeartbeatService: NSObject {
    
    private let bag = DisposeBag()
    private let queue = OperationQueue()
    private let delegate = Delegate()
    private lazy var backgroundSession: URLSession = {
        var configuration = URLSessionConfiguration.background(withIdentifier: "com.cyborch.dk.ku.smartsleep.heartbeat")
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        let delegate = Delegate()
        delegate.queue = self.queue
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: OperationQueue.current)
    }()
    private let foregroundSession = URLSession(configuration: .ephemeral)
    
    @objc static func storeHeartbeatUpdate() {
        let heartbeat = Heartbeat(id: nil, time: Date())
        heartbeat.save()
    }
    
    func fetch(from: Date, to: Date) -> [Heartbeat] {
        let service = DatabaseService.instance
        var result = [Heartbeat]()
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "select * from heartbeats where time >= ? and time <= ? order by time asc"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 2, to.timeIntervalSince1970)
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    result.append(Heartbeat(queryStatement: queryStatement!))
                }
            } else {
                NSLog("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    func deleteOld(to: Date) {
        let service = DatabaseService.instance
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "delete from heartbeats where time <= ?"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, to.timeIntervalSince1970)
                sqlite3_step(queryStatement)
            } else {
                NSLog("DELETE statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
    }
    
    func sync() -> Observable<HeartbeatProgressUpdate> {
        guard TokenService().token != nil else { return Observable.empty() }
        guard current == nil else { return current!.subject! }
        
        let observable = PublishSubject<HeartbeatProgressUpdate>()
        
        let completionHandler = CompletionHandler()
        completionHandler.subject = observable
        completionHandler.count = 1
        completionHandler.beginBackgroundTask()
        (backgroundSession.delegate as! Delegate).completion = completionHandler
        current = completionHandler
        
        let ud = UserDefaults()
        let lastSync = ud.valueFor(.lastHeartbeatSync) ?? Date(timeIntervalSinceNow: -48 * 60 * 60)
        let heartbeats = fetch(from: lastSync, to: Date())
        self.bulkPostHeartbeat(heartbeats, completion: completionHandler)
        deleteOld(to: lastSync)

        return observable
    }
    
    @objc static func backgroundSync() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let service = delegate.heartbeatService
        service.sync()
            .subscribe()
            .disposed(by: service.bag)
    }
    
    private func postHeartbeat(_ heartbeat: Heartbeat, completion: CompletionHandler) {
        let url = URL(string: baseUrl + "/heartbeat")!
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 500)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let json = try encoder.encode(heartbeat)
            let tmp = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
                .appendingPathComponent("\(heartbeat.time!.timeIntervalSinceReferenceDate).json")
            try json.write(to: tmp)
            let session = backgroundSession
            queue.addOperation {
                let task = session.uploadTask(with: request, fromFile: tmp)
                task.heartbeat = heartbeat
                task.resume()
            }
        } catch let error {
            NSLog("\(error)")
            queue.addOperation {
                completion.count -= 1
            }
        }
    }

    private func bulkPostHeartbeat(_ heartbeats: [Heartbeat], completion: CompletionHandler) {
        guard heartbeats.count > 0 else {
            queue.addOperation {
                completion.count = 0
            }
            return
        }
        let url = URL(string: baseUrl + "/heartbeat/bulk")!
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 500)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let json = try encoder.encode(heartbeats)
            let tmp = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
                .appendingPathComponent("\(heartbeats.first!.time!.timeIntervalSinceReferenceDate).json")
            try json.write(to: tmp)
            let session = backgroundSession
            queue.addOperation {
                let task = session.uploadTask(with: request, fromFile: tmp)
                task.heartbeat = heartbeats.last!
                task.resume()
            }
        } catch let error {
            NSLog("\(error)")
            queue.addOperation {
                completion.count = 0
            }
        }
    }

}

