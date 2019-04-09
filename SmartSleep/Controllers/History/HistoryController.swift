//
//  HistoryController.swift
//  SmartSleep
//
//  Created by Anders Borch on 07/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class HistoryController: UITableViewController {
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
