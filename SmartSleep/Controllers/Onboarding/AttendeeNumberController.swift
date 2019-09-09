//
//  AttendeeNumberController.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import RxSwift

class AttendeeNumberController: OnboardingController {

    private let forcedDelegate = AttendeeNumberDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if input.delegate == nil {
            input.delegate = forcedDelegate
            forcedDelegate.controller = self
            forcedDelegate.segueName = "Next"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ud = UserDefaults()
        ud.setValueFor(.attendeeCode, to: input.text!)
        ud.synchronize()
    }
}
