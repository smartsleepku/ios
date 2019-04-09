//
//  MainController.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import RxSwift

class MainController: UIViewController {
    
    @IBOutlet weak var openConfig: UIButton!
    
    private var once = false
    private var bag = DisposeBag()
    private var total = 0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bag = DisposeBag()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let mainView = self.view as! MainView
        delegate.synchronizeActivities()
        delegate.activityUpdates
            .timeout(5, scheduler: MainScheduler.instance)
            .catchErrorJustReturn(ActivityProgressUpdate(activity: nil, remaining: 0))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] update in
            if update.remaining == 0 {
                mainView.showUpdates(false)
                self?.total = 0
            } else {
                mainView.showUpdates(true)
                self?.total = max(self?.total ?? 0, update.remaining)
            }
            let progress = Float((self?.total ?? 0) - update.remaining) / Float(self?.total ?? 1)
            print("\(update.remaining) remaining of \(self!.total): \(progress)")
            mainView.progress.progress = progress
        }).disposed(by: bag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performSegue(withIdentifier: "Today", sender: nil)

        if ConfigurationService.configuration == nil {
            toggle()
            performSegue(withIdentifier: "Onboard", sender: nil)
        } else {
            AttendeeService.registerForPushNotifications()
        }
        guard once == false else { return }
        once = true
        (view as! MainView).appearAnimation()
    }
    
    @IBAction func toggle() {
        openConfig.isHidden = !openConfig.isHidden
    }
    
    @IBAction func closeConfiguration(segue: UIStoryboardSegue) {
        toggle()
        let configuration = children
            .filter { $0 is ConfigureController }
            .first
        UIView.animate(withDuration: 0.3,
                       animations: {
                        configuration?.view.alpha = 0
        }) { complete in
            guard complete else { return }
            configuration?.willMove(toParent: nil)
            configuration?.view.removeFromSuperview()
            configuration?.removeFromParent()
        }
    }

}
