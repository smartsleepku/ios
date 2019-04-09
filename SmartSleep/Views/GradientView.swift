//
//  GradientView.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit


class GradientView: UIView {
    private let gradient = CAGradientLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gradient.colors = [
            // 113061
            UIColor(displayP3Red: 0x11 / 255.0,
                    green: 0x30 / 255.0,
                    blue: 0x61 / 255.0,
                    alpha: 1).cgColor,
            // 00a4ff
            UIColor(displayP3Red: 0,
                    green: 0xa4 / 255.0,
                    blue: 1,
                    alpha: 1).cgColor
        ]
        layer.insertSublayer(gradient, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let status = UIApplication.shared.statusBarFrame.height
        let height = bounds.height
        gradient.locations = [
            NSNumber(floatLiteral: Double(status / height)),
            1
        ]
        gradient.frame = bounds
    }
    
    #if targetEnvironment(simulator)
    override func prepareForInterfaceBuilder() {
        setNeedsLayout()
    }
    #endif
}
