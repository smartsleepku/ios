//
//  ExplanationController.swift
//  SmartSleep
//
//  Created by Anders Borch on 08/06/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class ExplanationController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
    }
    
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
}
