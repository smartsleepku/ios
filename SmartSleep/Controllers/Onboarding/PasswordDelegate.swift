//
//  PasswordDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class PasswordDelegate: OnboardingTextDelegate {
    
    @IBOutlet weak var errorMessage: UIView!
    
    var valid = false
    private lazy var service: SleepStatusService = {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.sleepStatusService
    }()
    
    override func awakeFromNib() {
        service.fetchStatus { hasLocation in
            if hasLocation == true { self.segueName = "Next" }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorMessage.isHidden = true
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        errorMessage.isHidden = false
        textField.resignFirstResponder()
        guard textField.text?.lengthOfBytes(using: .utf8) ?? 0 > 0 else { return false }
        errorMessage.isHidden = true
        controller.performSegue(withIdentifier: segueName, sender: nil)
        return false
    }
}
