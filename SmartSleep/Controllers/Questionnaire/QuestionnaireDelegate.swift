//
//  QuestionnaireDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import WebKit

fileprivate let baseUrl = "https://smartsleep.cyborch.com"

class QuestionnaireDelegate: NSObject, WKNavigationDelegate {
    
    private let manager = TokenService()
    
    var survey: Survey? {
        didSet {
            once = false
        }
    }
    private var once = false
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let userId = manager.userId else { return }
        guard let survey = self.survey else { return }
        guard once == false else { return }
        once = true
        
        let url = URL(string: baseUrl + "/index.php/" + survey.sid + "?lang=da&token=" + userId)!
        webView.load(URLRequest(url: url))
    }
    
}
