//
//  AttendeeNumberDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import RxSwift

class AttendeeNumberDelegate: OnboardingTextDelegate {
    
    @IBOutlet weak var errorMessage: UIView!
    
    var valid = false
    
    private let manager = AuthenticationService()
    private var bag = DisposeBag()
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorMessage.isHidden = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let nsString = textField.text as NSString? else { return true }
        let newString = nsString.replacingCharacters(in: range, with: string)
        bag = DisposeBag()
        manager.validAttendee(code: newString)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] valid in
                self?.valid = valid
            }, onError: { error in
                print(error)
            })
            .disposed(by: bag)
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
