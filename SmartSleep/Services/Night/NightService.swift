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
    
    private let restService = RestService()
    private let queue = DispatchQueue(label: "dk.ku.nightservice.queue")
    
    private func nightThresholds(of date: Date, config: Configuration) -> (Date, Date) {
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
        let start = calendar.date(bySettingHour: evening.hour!, minute: evening.minute!, second: 0, of: date)
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
                print("SELECT statement could not be prepared")
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
                print("SELECT statement could not be prepared")
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
                let (from, _) = self.nightThresholds(of: date, config: ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration)
                sqlite3_bind_double(queryStatement, 1, from.timeIntervalSince1970)
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = Night(queryStatement: queryStatement!)
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    func generateNights() -> Completable {
        return Completable.create { completable in
            self.queue.async {
                var now = Date(timeIntervalSinceNow: -24 * 60 * 60)
                var from: Date
                var to: Date
                
                var periods: [Rest]?
                repeat {
                    (from, to) = self.nightThresholds(of: now, config: ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration)
                    print("generating night from \(from) to \(to)...")
                    now = now.addingTimeInterval(-24 * 60 * 60)

                    periods = self.restService.fetch(from: from, to: to)
                    print("found \(periods?.count ?? 0) rests")
                    var rests = [Rest]()
                    var unrests = [Rest]()
                    periods?.forEach {
                        if $0.resting! { rests.append($0) }
                        else { unrests.append($0) }
                        print("appending \($0) to \($0.resting! ? "rests" : "unrests")")
                    }
                    let night = Night(
                        from: from,
                        to: to,
                        disruptionCount: unrests.count,
                        longestSleepDuration: rests.reduce(0.0, {
                            max($0, $1.endTime!.timeIntervalSince($1.startTime!))
                        }),
                        unrestDuration: unrests.reduce(0.0, {
                            $0 + max($1.endTime!.timeIntervalSince($1.startTime!) - 4 * 60, 60)
                        })
                    )
                    night.save()
                } while periods?.count != 0
                completable(.completed)
            }
            return Disposables.create()
        }

    }
}
