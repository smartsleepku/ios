//
//  EmailDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class EmailDelegate: OnboardingTextDelegate {
    
    @IBOutlet weak var errorMessage: UIView!
    
    var valid = false
    
    private let validator = EmailValidator()
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorMessage.isHidden = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let nsString = textField.text as NSString? else { return true }
        let newString = nsString.replacingCharacters(in: range, with: string)
        valid = validator.validate(text: newString)
        return true
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard valid else {
            errorMessage.isHidden = false
            textField.resignFirstResponder()
            return false
        }
        controller.performSegue(withIdentifier: segueName, sender: nil)
        return false
    }
}
