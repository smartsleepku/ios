//
//  PickerSegue.swift
//  SmartSleep
//
//  Created by Anders Borch on 01/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class PickerSegue: UIStoryboardSegue {
    var configuration: PickerConfiguration?
    
    let overlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        return overlay
    }()
    
    override func perform() {
        let source = self.source.parent!
        
        let rect = CGRect(x: source.view.center.x - 155,
                          y: source.view.center.y - 202.5,
                          width: 310,
                          height: 405)

        let destination = self.destination as! PickerController
        destination.configuration = configuration
        destination.view.frame = rect
        destination.overlay = overlay

        overlay.frame = source.view.bounds
        source.view.addSubview(overlay)
        
        source.view.addSubview(destination.view)
        source.addChild(destination)
        destination.didMove(toParent: source)

        destination.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            destination.view.alpha = 1
        }
    }
}
