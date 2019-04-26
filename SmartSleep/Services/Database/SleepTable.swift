//
//  SleepTable.swift
//  SmartSleep
//
//  Created by Anders Borch on 17/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import SQLite3

extension Sleep {
    
    static func initializeDatabase(with db: OpaquePointer) {
        let createTableString = "create table if not exists sleeps(" +
            "id integer primary key autoincrement," +
            "\"time\" real not null unique," +
            "\"sleeping\" integer not null)"
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            sqlite3_step(createTableStatement)
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    init(queryStatement: OpaquePointer) {
        id = Int(sqlite3_column_int64(queryStatement, 0))
        time = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 1))
        sleeping = Bool(sqlite3_column_int(queryStatement, 2) != 0)
    }
    
    func save() {
        let service = DatabaseService.instance
        service.queue.async {
            var statement: OpaquePointer? = nil
            if self.id == nil {
                let insertStatementString = "insert or replace into sleeps (\"time\", sleeping) " +
                "values (?, ?)"
                sqlite3_prepare_v2(service.db, insertStatementString, -1, &statement, nil)
            } else {
                let updateStatementString = "update sleeps set (\"time\" = ?, sleeping = ?) " +
                "where id = ?"
                sqlite3_prepare_v2(service.db, updateStatementString, -1, &statement, nil)
                sqlite3_bind_int64(statement, 3, Int64(self.id!))
            }
            sqlite3_bind_double(statement, 1, self.time!.timeIntervalSince1970)
            sqlite3_bind_int64(statement, 2, Int64(self.sleeping! ? 1 : 0))
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }
    
}
