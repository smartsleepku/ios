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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ud = UserDefaults()
        ud.setValueFor(.attendeeCode, to: input.text!)
        ud.synchronize()
    }
}
