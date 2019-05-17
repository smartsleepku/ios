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
    
    func updateLatestRest(with sleep: Sleep) {
        let service = DatabaseService.instance
        var result: Rest? = nil
        service.queue.sync {
            var queryStatement: OpaquePointer? = nil
            let queryStatementString = """
                select *
                from rests
                order by startTime desc
                limit 1
            """
            if sqlite3_prepare_v2(service.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    result = Rest(queryStatement: queryStatement!)
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        if result == nil {
            Rest(id: nil, resting: sleep.sleeping, startTime: sleep.time, endTime: nil).save()
        } else if result?.resting! != sleep.sleeping! {
            result?.endTime = sleep.time
            result?.save()
            Rest(id: nil, resting: sleep.sleeping, startTime: sleep.time, endTime: nil).save()
        }
    }
}
