//
//  MainController.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import RxSwift
import Reachability

class MainController: UIViewController {
    
    @IBOutlet weak var openConfig: UIButton!
    @IBOutlet weak var tabBar: UITabBar!

    private var once = false
    private var bag = DisposeBag()
    private var total = 0

    private let reachability = Reachability()!
    private lazy var alert: UIAlertController = {
        let alert = UIAlertController(title: NSLocalizedString("Title",
                                                               tableName: "Main",
                                                               bundle: .main,
                                                               value: "Ingen Forbindelse",
                                                               comment: ""),
                                      message: NSLocalizedString("Text",
                                                                 tableName: "Welcome",
                                                                 bundle: .main,
                                                                 value: "Der er ingen forbindelse til server. " +
                                        "Check din internetforbindelse og prøv igen.",
                                                                 comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                      style: .default,
                                      handler: { _ in
                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                  options: [:],
                                                                  completionHandler: nil)
        }))
        return alert
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.sleepStatusService.fetchStatus { hasLocation in
            SleepStatusHelper().registerAppforSleepStatus()
        }
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(willEnterForeground),
                       name: UIApplication.willEnterForegroundNotification,
                       object: nil)
    }

    deinit {
        let nc = NotificationCenter.default
        nc.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func willEnterForeground() {
        viewWillAppear(true)
        viewDidAppear(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bag = DisposeBag()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let mainView = self.view as! MainView
        delegate.sleepUpdates
            .timeout(5, scheduler: MainScheduler.instance)
            .catchErrorJustReturn(SleepProgressUpdate(sleep: nil, remaining: 0))
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
        delegate.synchronizeSleep()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performSegue(withIdentifier: "Today", sender: nil)

        if ConfigurationService.configuration == nil {
            toggle()
            performSegue(withIdentifier: "Onboard", sender: nil)
        } else {
            AttendeeService.registerForPushNotifications(controller: self)
        }

        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.audioService.verifyAuthorization(controller: self)
        delegate.audioService.startRecording()

        reachability.whenUnreachable = { [weak self] _ in
            guard let this = self else { return }
            this.present(this.alert, animated: true, completion: nil)
        }
        
        reachability.whenReachable = { [weak self] _ in
            guard self?.alert.presentingViewController != nil else { return }
            self?.alert.dismiss(animated: true, completion: nil)
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
        guard once == false else { return }
        once = true
        (view as! MainView).appearAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
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
            AttendeeService.registerForPushNotifications(controller: self)
        }
    }
}
