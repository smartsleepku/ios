//
//  WelcomeController.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import Reachability

class WelcomeController: UIViewController {
    
    private let reachability = Reachability()!
    private lazy var alert: UIAlertController = {
        let alert = UIAlertController(title: NSLocalizedString("Title",
                                                               tableName: "Welcome",
                                                               bundle: .main,
                                                               value: "Ingen Forbindelse",
                                                               comment: ""),
                                      message: NSLocalizedString("Text",
                                                                 tableName: "Welcome",
                                                                 bundle: .main,
                                                                 value: "Der er ingen forbindelse til server. Check din internetforbindelse og prøv igen.",
                                                                 comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                      style: .default,
                                      handler: { _ in
                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                  options: [:],
                                                                  completionHandler: nil)
        }))
        return alert
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func register() {
        UIApplication.shared.open(URL(string: "https://smartsleep.ku.dk")!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reachability.whenUnreachable = { [weak self] _ in
            guard let this = self else { return }
            this.present(this.alert, animated: true, completion: nil)
        }
        
        reachability.whenReachable = { [weak self] _ in
            guard self?.alert.presentingViewController != nil else { return }
            self?.alert.dismiss(animated: true, completion: nil)
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            NSLog("Unable to start notifier")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
    }
}
