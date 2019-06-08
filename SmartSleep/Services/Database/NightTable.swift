//
//  NightTable.swift
//  SmartSleep
//
//  Created by Anders Borch on 06/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import SQLite3

extension Night {

    static func initializeDatabase(with db: OpaquePointer) {
        let createTableString = "create table if not exists nights(" +
            "id integer primary key autoincrement," +
            "\"from\" real not null unique," +
            "\"to\" real not null," +
            "disruptionCount integer not null," +
            "longestSleepDuration real not null," +
            "unrestDuration real not null)"
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            sqlite3_step(createTableStatement)
        } else {
            NSLog("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    init(queryStatement: OpaquePointer) {
        id = Int(sqlite3_column_int64(queryStatement, 0))
        from = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 1))
        to = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 2))
        disruptionCount = Int(sqlite3_column_int(queryStatement, 3))
        longestSleepDuration = sqlite3_column_double(queryStatement, 4)
        unrestDuration = sqlite3_column_double(queryStatement, 5)
    }
    
    func save() {
        let service = DatabaseService.instance
        service.queue.async {
            var statement: OpaquePointer? = nil
            if self.id == nil {
                let insertStatementString = "insert or replace into nights (\"from\", \"to\", disruptionCount, longestSleepDuration, unrestDuration) " +
                "values (?, ?, ?, ?, ?)"
                sqlite3_prepare_v2(service.db, insertStatementString, -1, &statement, nil)
            } else {
                let updateStatementString = "update nights set (\"from\" = ?, \"to\" = ?, disruptionCount = ?, longestSleepDuration = ?, unrestDuration = ?) " +
                "where id = ?"
                sqlite3_prepare_v2(service.db, updateStatementString, -1, &statement, nil)
                sqlite3_bind_int64(statement, 6, Int64(self.id!))
            }
            sqlite3_bind_double(statement, 1, self.from!.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, self.to!.timeIntervalSince1970)
            sqlite3_bind_int64(statement, 3, Int64(self.disruptionCount!))
            sqlite3_bind_double(statement, 4, self.longestSleepDuration!)
            sqlite3_bind_double(statement, 5, self.unrestDuration!)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }

}
