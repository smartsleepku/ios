//
//  CALayer+UIColor.swift
//  SmartSleep
//
//  Created by Anders Borch on 08/06/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

extension CALayer {
    @IBInspectable var borderUIColor: UIColor? {
        get {
            guard borderColor != nil else { return nil }
            return UIColor(cgColor: borderColor!)
        }
        set(value) {
            borderColor = value?.cgColor
        }
    }
}
