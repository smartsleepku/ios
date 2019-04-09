//
//  WelcomeController.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class WelcomeController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func register() {
        UIApplication.shared.open(URL(string: "https://smartsleep.ku.dk")!)
    }
}
