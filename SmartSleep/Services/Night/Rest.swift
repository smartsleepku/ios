//
//  Rest.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation

struct Rest: Codable {
    var id: String?
    var resting: Bool?
    var startTime: Date?
    var endTime: Date?
}
