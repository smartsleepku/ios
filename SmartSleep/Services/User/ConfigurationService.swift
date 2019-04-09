//
//  ConfigurationService.swift
//  SmartSleep
//
//  Created by Anders Borch on 27/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation

struct Configuration: Codable {
    var weekdayMorning: Date
    var weekdayEvening: Date
    var weekendMorning: Date
    var weekendEvening: Date
}

extension Date {
    static func withHour(_ hour: Int) -> Date {
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date(), matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)!
    }
}

class ConfigurationService {
    
    static let defaultConfiguration = Configuration(
        weekdayMorning: Date.withHour(7),
        weekdayEvening: Date.withHour(22),
        weekendMorning: Date.withHour(10),
        weekendEvening: Date.withHour(23)
    )
    
    static var configuration: Configuration? {
        get {
            let ud = UserDefaults()
            guard let data: Data = ud.valueFor(.configuration) else { return nil }
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(Configuration.self, from: data)
            } catch {
                return nil
            }
        }
        set(value) {
            let ud = UserDefaults()
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(value)
                ud.setValueFor(.configuration, to: data)
                ud.synchronize()
            } catch let error {
                NSLog("Error saving user: \(error)")
            }
        }
    }
}
