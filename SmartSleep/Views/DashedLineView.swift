//
//  DashedLineView.swift
//  SmartSleep
//
//  Created by Anders Borch on 01/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class DashedLineView: UIView {
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.gray.cgColor
        shapeLayer.lineWidth = 1
        // passing an array with the values [2,3] sets a dash pattern that alternates between a 2-user-space-unit-long painted segment and a 3-user-space-unit-long unpainted segment
        shapeLayer.lineDashPattern = [2,3]
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: (bounds.height / 2).rounded(.down)))
        path.addLine(to: CGPoint(x: bounds.width, y: (bounds.height / 2).rounded(.down)))
        shapeLayer.path = path
        layer.addSublayer(shapeLayer)
        return shapeLayer
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = self.bounds
    }
}
