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
    
    @IBOutlet weak var errorMessage: UIView!
    private let authManager = AuthenticationService()
    private let credentialsManager = CredentialsService()
    private let forcedDelegate = PasswordDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        input.delegate = forcedDelegate
        forcedDelegate.errorMessage = errorMessage
        forcedDelegate.controller = self
        forcedDelegate.segueName = "Next"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ud = UserDefaults()
        var credentials = credentialsManager.credentials!
        credentials.password = input.text!
        credentialsManager.credentials = credentials
        authManager.postCredentials(toAttendee: ud.valueFor(.attendeeCode)!)
    }
}
