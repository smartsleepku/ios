//
//  NightService.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import RxSwift
import SQLite3

class NightService {

    private lazy var restService: RestService = {
        var delegate: AppDelegate? = nil
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                delegate = UIApplication.shared.delegate as? AppDelegate
            }
        } else {
            delegate = UIApplication.shared.delegate as? AppDelegate
        }
        return delegate!.restService
    }()
    private let queue = DispatchQueue(label: "dk.ku.nightservice.queue")
    
    static func nightThresholds(of date: Date, config: Configuration) -> (Date, Date) {
        let calendar = Calendar.current
        var morning: DateComponents!
        var evening: DateComponents!
        if calendar.isDateInWeekend(date) {
            morning = calendar.dateComponents([.hour, .minute], from: config.weekendMorning)
            evening = calendar.dateComponents([.hour, .minute], from: config.weekendEvening)
        } else {
            morning = calendar.dateComponents([.hour, .minute], from: config.weekdayMorning)
            evening = calendar.dateComponents([.hour, .minute], from: config.weekdayEvening)
        }
        var start = calendar.date(bySettingHour: evening.hour!, minute: evening.minute!, second: 0, of: date)
        if start! > date {
            start = calendar.date(bySettingHour: evening.hour!, minute: evening.minute!, second: 0, of: date.addingTimeInterval(-24 * 60 * 60))
        }
        let end = calendar.nextDate(after: start!, matching: morning, matchingPolicy: .nextTime)
        return (start!, end!)
    }
    
    func fetch() -> [Night] {
        let service = DatabaseService.instance
        var result = [Night]()
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "select * from nights order by \"from\" asc"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    result.append(Night(queryStatement: queryStatement!))
                }
            } else {
                NSLog("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    func count() -> Int {
        let service = DatabaseService.instance
        var result = 0
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "select count(1) from nights"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = Int(sqlite3_column_int64(queryStatement, 0))
                }
            } else {
                NSLog("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }

    func fetchOne(at date: Date) -> Night? {
        let service = DatabaseService.instance
        var result: Night? = nil
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "select * from nights where \"from\" = ?"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                let (from, _) = NightService.nightThresholds(of: date, config: ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration)
                sqlite3_bind_double(queryStatement, 1, from.timeIntervalSince1970)
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = Night(queryStatement: queryStatement!)
                }
            } else {
                NSLog("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    private func purgeNights() {
        let service = DatabaseService.instance
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = "delete from nights"
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_step(queryStatement)
            } else {
                NSLog("delete statement could not be prepared")
            }
        }
    }
    
    func generateNights() -> Completable {
        return Completable.create { completable in
            self.purgeNights()
            self.queue.async {
                var now = Date()
                var from: Date
                var to: Date
                let first = self.restService.fetchFirstRestTime()
                repeat {
                    (from, to) = NightService.nightThresholds(of: now, config: ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration)
                    NSLog("generating night from \(from) to \(to)...")
                    now = now.addingTimeInterval(-24 * 60 * 60)
                    let night = Night(
                        from: from,
                        to: to,
                        disruptionCount: self.restService.fetchUnrestCount(from: from, to: to),
                        longestSleepDuration: self.restService.fetchLongestRest(from: from, to: to),
                        unrestDuration: self.restService.fetchTotalUnrest(from: from, to: to)
                    )
                    night.save()
                } while from > first
                completable(.completed)
            }
            return Disposables.create()
        }

    }
}
