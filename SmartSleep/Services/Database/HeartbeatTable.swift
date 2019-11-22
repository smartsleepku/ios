//
//  HeartbeatTable.swift
//  SmartSleep
//
//  Created on 11/10/19.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import SQLite3

extension Heartbeat {
    
    static func initializeDatabase(with db: OpaquePointer) {
        let createTableString = "create table if not exists heartbeats(" +
            "id integer primary key autoincrement," +
            "\"time\" real not null unique)"
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
        time = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 1))
    }
    
    func save() {
        let service = DatabaseService.instance
        service.queue.sync {
            var statement: OpaquePointer? = nil
            if self.id == nil {
                let insertStatementString = "insert or replace into heartbeats (\"time\") " +
                "values (?)"
                sqlite3_prepare_v2(service.db, insertStatementString, -1, &statement, nil)
            } else {
                let updateStatementString = "update heartbeats set (\"time\" = ?) " +
                "where id = ?"
                sqlite3_prepare_v2(service.db, updateStatementString, -1, &statement, nil)
                sqlite3_bind_int64(statement, 3, Int64(self.id!))
            }
            sqlite3_bind_double(statement, 1, self.time!.timeIntervalSince1970)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }
    
}
