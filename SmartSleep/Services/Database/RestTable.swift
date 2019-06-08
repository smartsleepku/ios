//
//  RestTable.swift
//  SmartSleep
//
//  Created by Anders Borch on 06/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import SQLite3

extension Rest {
    static func initializeDatabase(with db: OpaquePointer) {
        let createTableString = "create table if not exists rests(" +
            "id char(24) primary key not null," +
            "resting integer," +
            "startTime real," +
            "endTime real)"
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            sqlite3_step(createTableStatement)
        } else {
            NSLog("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }

    init(queryStatement: OpaquePointer) {
        id = String(cString: sqlite3_column_text(queryStatement, 0))
        resting = sqlite3_column_int(queryStatement, 1) == 1
        startTime = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 2))
        endTime = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 3))
    }
    
    mutating func save() {
        let service = DatabaseService.instance
        if id == nil { id = UUID().uuidString.lowercased() }
        service.queue.sync {
            let insertStatementString = "insert or replace into rests (id, resting, startTime, endTime) values (?, ?, ?, ?)"
            NSLog("inserting \(self)")
            var insertStatement: OpaquePointer? = nil
            if sqlite3_prepare_v2(service.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, self.id, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(insertStatement, 2, self.resting! ? 1 : 0)
                sqlite3_bind_double(insertStatement, 3, self.startTime!.timeIntervalSince1970)
                if self.endTime != nil { sqlite3_bind_double(insertStatement, 4, self.endTime!.timeIntervalSince1970) }
                else { sqlite3_bind_null(insertStatement, 4) }
                sqlite3_step(insertStatement)
                NSLog("\(String(cString: sqlite3_errmsg(service.db)))")
            } else {
                NSLog("INSERT statement could not be prepared.")
            }
            sqlite3_finalize(insertStatement)
        }
    }
}
