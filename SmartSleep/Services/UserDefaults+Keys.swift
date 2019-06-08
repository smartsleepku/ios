//
//  UserDefaults+Keys.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation

extension UserDefaults {
    public enum Key: String {
        case attendeeCode, username, configuration, lastActivitySync, lastSleepSync, lastRestSync, paused
    }
    
    func valueFor<T>(_ key: Key) -> T? {
        return self.value(forKey: key.rawValue) as? T
    }
    
    func setValueFor(_ key: Key, to value: Any) {
        self.set(value, forKey: key.rawValue)
    }
}
