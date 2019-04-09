//
//  EmailController.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class EmailController: OnboardingController {
    
    private let manager = CredentialsService()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        manager.credentials = Credentials(
            username: input.text ?? "",
            password: ""
        )
    }
}
