//
//  EmailController.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class EmailController: OnboardingController {
    
    @IBOutlet weak var errorMessage: UIView!

    private let manager = CredentialsService()
    private let forcedDelegate = EmailDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        input.delegate = forcedDelegate
        forcedDelegate.errorMessage = errorMessage
        forcedDelegate.controller = self
        forcedDelegate.segueName = "Next"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        manager.credentials = Credentials(
            username: input.text ?? "",
            password: ""
        )
    }
}
