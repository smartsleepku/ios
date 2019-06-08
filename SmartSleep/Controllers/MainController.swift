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
    @IBOutlet weak var openHelp: UIButton!
    @IBOutlet weak var tabBar: UITabBar!

    private var once = false
    private var bag = DisposeBag()
    private var total = 0
    private weak var tonight: TonightController?
    private weak var config: ConfigureController?

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
            guard hasLocation else { return }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ConfigureController {
            config = segue.destination as? ConfigureController
        }
        if segue.identifier == "Today" {
            openConfig.isHidden = false
            openHelp.isHidden = true
            tonight = segue.destination as? TonightController
        } else {
            openConfig.isHidden = true
            openHelp.isHidden = false
        }
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
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        bag = DisposeBag()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let mainView = self.view as! MainView
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
            NSLog("\(update.remaining) remaining of \(self!.total): \(progress)")
            mainView.progress.progress = progress
        }).disposed(by: bag)
        delegate.synchronizeSleep()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performSegue(withIdentifier: "Today", sender: nil)

        if ConfigurationService.configuration == nil {
            openConfig.isHidden = true
            openHelp.isHidden = false
            performSegue(withIdentifier: "Onboard", sender: nil)
        } else {
            AttendeeService.registerForPushNotifications(controller: self)
        }

        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.locationService.verifyAuthorization(controller: self)
        let ud = UserDefaults()
        if (ud.valueFor(.paused) ?? false) == false {
            delegate.locationService.start()
            delegate.audioService.startRecording()
        }

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
            NSLog("Unable to start notifier")
        }
        
        guard once == false else { return }
        once = true
        (view as! MainView).appearAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
    }
    
    @IBAction func closeConfiguration(segue: UIStoryboardSegue) {
        openConfig.isHidden = false
        openHelp.isHidden = true
        tonight?.updateLabels()
        tonight?.updateLastNight()
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
