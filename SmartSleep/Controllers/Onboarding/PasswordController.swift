//
//  PasswordController.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import KeychainAccess

class PasswordController: OnboardingController {
    
    private let authManager = AuthenticationService()
    private let credentialsManager = CredentialsService()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ud = UserDefaults()
        var credentials = credentialsManager.credentials!
        credentials.password = input.text!
        credentialsManager.credentials = credentials
        authManager.postCredentials(toAttendee: ud.valueFor(.attendeeCode)!)
    }
}
