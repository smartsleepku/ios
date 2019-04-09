//
//  ConfigureSegue.swift
//  SmartSleep
//
//  Created by Anders Borch on 27/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class ConfigurationSegue: UIStoryboardSegue {
    
    override func perform() {
        let main = source as! MainController
        let mainView = main.view as! MainView
        let destination = self.destination
        main.addChild(destination)
        
        destination.view.translatesAutoresizingMaskIntoConstraints = false
        mainView.content.addSubview(destination.view)
        let margins = mainView.content.layoutMarginsGuide
        destination.view.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        destination.view.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        destination.view.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        destination.view.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        
        destination.didMove(toParent: main)
        
        destination.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            destination.view.alpha = 1
        }
    }
}
