//
//  TonightView.swift
//  SmartSleep
//
//  Created by Anders Borch on 07/07/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class TonightView: UIView {
    @IBOutlet weak var sleepDuration: UILabel!
    @IBOutlet weak var unrestDuration: UILabel!
    @IBOutlet weak var disruptionCount: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.bounds.width <= 320 else { return }
        [sleepDuration, unrestDuration, disruptionCount].forEach { label in
            label?.font = UIFont(name: "HelveticaNeue-Light", size: 14)!
        }
    }
}
