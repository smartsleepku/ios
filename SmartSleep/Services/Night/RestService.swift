//
//  RestService.swift
//  SmartSleep
//
//  Created by Anders Borch on 03/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import RxSwift
import SQLite3

fileprivate let formatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter
}()

class RestService {
    
    enum RestError: Error {
        case httpError(statusCode: Int)
    }
    
    private let session = URLSession(configuration: .ephemeral)

    var lastSync: Date {
        get {
            let ud = UserDefaults()
            return ud.valueFor(.lastRestSync) ?? Date(timeIntervalSinceNow: -24 * 60 * 60)
        }
        set(value) {
            let ud = UserDefaults()
            ud.setValueFor(.lastRestSync, to: value)
            ud.synchronize()
        }
    }
    
    func fetch(from: Date, to: Date) -> [Rest] {
        let service = DatabaseService.instance
        var result = [Rest]()
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "select * from rests where startTime >= ? and startTime <= ? order by startTime asc"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 2, to.timeIntervalSince1970)
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    result.append(Rest(queryStatement: queryStatement!))
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    func fetchTotalUnrest(from: Date, to: Date) -> TimeInterval {
        let service = DatabaseService.instance
        var result: Int64 = 0
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = """
                select sum(cast((min(endTime,?) - max(startTime,?)) as integer))
                from rests
                where endTime > ? and startTime < ?
                and resting = 0
            """
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, to.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 2, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 3, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 4, to.timeIntervalSince1970)
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = sqlite3_column_int64(queryStatement, 0)
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return TimeInterval(result)
    }
    
    func fetchUnrestCount(from: Date, to: Date) -> Int {
        let service = DatabaseService.instance
        var result: Int64 = 0
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = """
                select count(1)
                from rests
                where endTime > ? and startTime < ?
                and resting = 0
            """
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 2, to.timeIntervalSince1970)
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = sqlite3_column_int64(queryStatement, 0)
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return Int(result)
    }
    
    func fetchLongestRest(from: Date, to: Date) -> TimeInterval {
        let service = DatabaseService.instance
        var result: Int64 = 0
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = """
                select max(cast((min(endTime,?) - max(startTime,?)) as integer))
                from rests
                where endTime > ? and startTime < ?
                and resting = 1
            """
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(queryStatement, 1, to.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 2, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 3, from.timeIntervalSince1970)
                sqlite3_bind_double(queryStatement, 4, to.timeIntervalSince1970)
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = sqlite3_column_int64(queryStatement, 0)
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return TimeInterval(result)
    }
    
    func fetchFirstRestTime() -> Date {
        let service = DatabaseService.instance
        var result: Int64 = 0
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = """
                select min(startTime)
                from rests
            """
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = sqlite3_column_int64(queryStatement, 0)
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        guard result > 0 else { return Date() }
        return Date(timeIntervalSince1970: TimeInterval(result))
    }
    
    func sync(from: Date, to: Date) -> Observable<Rest> {
        return Observable.create { [weak self] observer in
            let url = URL(string: baseUrl + "/rest?from=" +
                formatter.string(from: from).replacingOccurrences(of: "+", with: "%2b") + "&to=" +
                formatter.string(from: to).replacingOccurrences(of: "+", with: "%2b")
                )!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
            let task = self?.session.dataTask(with: request) { (data, response, error) in
                guard error == nil else {
                    observer.on(.error(error!))
                    return
                }
                guard (response as! HTTPURLResponse).statusCode == 200 else {
                    observer.on(.error(RestError.httpError(statusCode: (response as! HTTPURLResponse).statusCode)))
                    return
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                do {
                    let result = try decoder.decode([Rest].self, from: data!)
                    result.forEach {
                        $0.insert()
                        if let date = $0.endTime { self?.lastSync = date }
                        observer.on(.next($0))
                    }
                    observer.on(.completed)
                } catch let error {
                    observer.on(.error(error))
                }
            }
            task?.resume()
            
            return Disposables.create {
                task?.cancel()
            }
        }
    }
    
    func syncLastNight() -> Observable<Rest> {
        let config = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        let calendar = Calendar.current
        let yesterday = Date(timeIntervalSinceNow: -24 * 60 * 60)
        var morning: DateComponents!
        var evening: DateComponents!
        if calendar.isDateInWeekend(yesterday) {
            morning = calendar.dateComponents([.hour, .minute], from: config.weekendMorning)
            evening = calendar.dateComponents([.hour, .minute], from: config.weekendEvening)
        } else {
            morning = calendar.dateComponents([.hour, .minute], from: config.weekdayMorning)
            evening = calendar.dateComponents([.hour, .minute], from: config.weekdayEvening)
        }
        let lastNight = calendar.date(bySettingHour: evening.hour!, minute: evening.minute!, second: 0, of: yesterday)
        let lastMorning = calendar.nextDate(after: lastNight!, matching: morning, matchingPolicy: .nextTime)
        return sync(from: lastNight!, to: lastMorning!)
    }
    
    func sync() -> Observable<Rest> {
        let now = Date()
        return sync(from: lastSync, to: now)
    }
}
