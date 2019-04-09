//
//  SplashController.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import CoreMotion

class SplashController: UIViewController {

    private let manager = CredentialsService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if manager.credentials == nil {
            performSegue(withIdentifier: "Welcome", sender: nil)
        } else {
            performSegue(withIdentifier: "Run", sender: nil)
        }
    }
    
}

