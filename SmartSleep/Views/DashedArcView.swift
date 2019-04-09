//
//  DashedArcView.swift
//  SmartSleep
//
//  Created by Anders Borch on 08/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class DashedArcView: UIView {
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.gray.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1
        // passing an array with the values [2,3] sets a dash pattern that alternates between a 2-user-space-unit-long painted segment and a 3-user-space-unit-long unpainted segment
        shapeLayer.lineDashPattern = [2,3]
        
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: 1, y: 1, width: bounds.width - 2, height: bounds.height * 2))
        shapeLayer.path = path
        layer.addSublayer(shapeLayer)
        return shapeLayer
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = true
        shapeLayer.frame = self.bounds
    }
}
