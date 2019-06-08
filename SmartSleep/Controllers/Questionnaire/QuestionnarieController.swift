//
//  QuestionnarieController.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import WebKit
import RxSwift

class QuestionnarieController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    private var manager = SurveyService()
    private let bag = DisposeBag()
    private let delegate = QuestionnaireDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = delegate
        
        manager.fetchSessionKey()
            .asObservable()
            .flatMap { self.manager.fetchSurveys(sessionKey: $0) }
            .filter { $0.active == "Y" }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] survey in
                self?.load(survey: survey)
            }, onError: { error in
                NSLog("\(error)")
            })
            .disposed(by: bag)
    }
    
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
    
    func load(survey: Survey) {
        delegate.survey = survey
        let url = URL(string: baseUrl + "/auth/setcookie?auth=" + (TokenService().token ?? ""))!
        webView.load(URLRequest(url: url))
    }
}
