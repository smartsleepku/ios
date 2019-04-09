//
//  MainTabDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import SafariServices

class MainTabDelegate: NSObject, UITabBarDelegate {
    
    weak var controller: UIViewController?
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            tabBar.selectedItem = nil
        }
        switch item.tag {
        case 0:
            showSurvey()
        case 1:
            showHistory()
        case 2:
            showAdvice()
        default:
            break
        }
    }
    
    private func showSurvey() {
        controller?.performSegue(withIdentifier: "Questionnaire", sender: nil)
    }
    
    private func showAdvice() {
        let url = URL(string: "https://www.smartsleep.ku.dk/gode-raad-om-soevn/")!
        let config = SFSafariViewController.Configuration()
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.modalTransitionStyle = .coverVertical
        safari.modalPresentationStyle = .overCurrentContext
        controller?.present(safari, animated: true, completion: nil)
    }
    
    private func showHistory() {
        controller?.performSegue(withIdentifier: "History", sender: nil)
    }
}
