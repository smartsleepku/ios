//
//  DatabaseService.swift
//  SmartSleep
//
//  Created by Anders Borch on 06/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import SQLite3

let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class DatabaseService {
    
    let db: OpaquePointer?
    let queue = DispatchQueue(label: "dk.ku.dbservice.queue")
    static let instance = DatabaseService()
    
    private init() {
        let path = try! FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
            .appendingPathComponent("SmartSleep.db")
            .absoluteString
            .replacingOccurrences(of: "file://", with: "")
        db = DatabaseService.openDatabase(path)
        queue.async {
            self.initializeDatabase()
            Rest.initializeDatabase(with: self.db!)
            Night.initializeDatabase(with: self.db!)
            Sleep.initializeDatabase(with: self.db!)
        }
    }
    
    private func initializeDatabase() {
        let createTableString = "create table if not exists version(" +
            "major integer unique," +
            "minor integer unique)"
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            sqlite3_step(createTableStatement)
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
        
        let insertStatementString = "insert or ignore into version (major, minor) values (?, ?)"
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, "1".cString(using: .utf8), -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(insertStatement, 2, "0".cString(using: .utf8), -1, SQLITE_TRANSIENT)
            sqlite3_step(insertStatement)
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    private static func openDatabase(_ path: String) -> OpaquePointer? {
        var db: OpaquePointer? = nil
        if sqlite3_open(path, &db) == SQLITE_OK {
            return db
        } else {
            return nil
        }
    }
}
