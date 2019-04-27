//
//  Activity.swift
//  SmartSleep
//
//  Created by Anders Borch on 17/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation

struct Activity: Codable {
    var type: String
    var confidence: Int
    var time: Date
}
