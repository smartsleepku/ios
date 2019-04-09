//
//  OnboardingTextDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class OnboardingTextDelegate: NSObject, UITextFieldDelegate {
    @IBOutlet weak var controller: UIViewController!
    @IBInspectable var segueName: String!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        controller.performSegue(withIdentifier: segueName, sender: nil)
        return false
    }
}
