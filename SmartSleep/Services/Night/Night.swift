//
//  Night.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation

struct Night {
    var id: Int?
    var from: Date?
    var to: Date?
    var disruptionCount: Int?
    var longestSleepDuration: TimeInterval?
    var unrestDuration: TimeInterval?
    
    init(from: Date?, to: Date?, disruptionCount: Int?, longestSleepDuration: Double?, unrestDuration: Double?) {
        id = nil
        self.from = from
        self.to = to
        self.disruptionCount = disruptionCount
        self.longestSleepDuration = longestSleepDuration
        self.unrestDuration = unrestDuration
    }
}
