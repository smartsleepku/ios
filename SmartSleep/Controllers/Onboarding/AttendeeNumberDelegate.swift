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
        textField.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
    }
    
    @objc func textChanged(_ textField: UITextField) {
        bag = DisposeBag()
        manager.validAttendee(code: textField.text ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] valid in
                self?.valid = valid
                }, onError: { error in
                    print(error)
            })
            .disposed(by: bag)

    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard valid else {
            errorMessage.isHidden = false
            textField.resignFirstResponder()
            return false
        }
        textField.removeTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
        controller.performSegue(withIdentifier: segueName, sender: nil)
        return false
    }
}
