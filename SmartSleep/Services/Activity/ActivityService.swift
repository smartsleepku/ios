//
//  ActivityService.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import CoreMotion

class ActivityService {
    
    private let queue = OperationQueue()
    private let manager = CMMotionActivityManager()
    
    func sync() {
        // Since we're using screen on/off state, this is basically here to
        // fool Apple into thinking we're doing something legit.
        manager.queryActivityStarting(from: Date(timeIntervalSinceNow: -24 * 60 * 60),
                                      to: Date(),
                                      to: queue,
                                      withHandler: { _, _ in })
    }
}
