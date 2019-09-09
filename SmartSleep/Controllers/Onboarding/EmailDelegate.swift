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
        errorMessage.isHidden = false
        textField.resignFirstResponder()
        // EmailValidator seems to be broken in iOS 12.4, use naive email test for now
        guard textField.text!.contains("@") else { return false }
        let at = textField.text!.index(of: "@")!
        guard at > textField.text!.startIndex else { return false }
        guard let dot = textField.text!.lastIndex(of: ".") else { return false }
        guard dot > at else { return false }
        guard dot < textField.text!.endIndex else { return false }
        errorMessage.isHidden = true
        controller.performSegue(withIdentifier: segueName, sender: nil)
        return false
    }
}
