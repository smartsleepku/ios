//
//  TonightController.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import RxSwift

fileprivate let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

class TonightController: UIViewController {
    @IBOutlet weak var morning: UILabel!
    @IBOutlet weak var evening: UILabel!
    @IBOutlet weak var tabBarDelegate: MainTabDelegate!
    @IBOutlet weak var disruptionCount: UILabel!
    @IBOutlet weak var longestSleepDuration: UILabel!
    @IBOutlet weak var unrestDuration: UILabel!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    private var timer: Timer?

    private var bag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        timer?.invalidate()
        timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            // NOTE: seems to be the approx correction to get real decibels
            let correction: Float = 90
            let power = delegate.audioService.delegate.powerLevel + correction
            let format = NSLocalizedString("CurrentPower",
                                           tableName: "Tonight",
                                           bundle: .main,
                                           value: "Nuværende støjniveau: %d dB",
                                           comment: "")
            self?.power.text = String(format: format, Int(power))
        }
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarDelegate!.controller = self
    }
    
    func updateLabels() {
        let userConfig = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday <= 6 {
            morning.text = timeFormatter.string(from: userConfig.weekdayMorning)
            evening.text = timeFormatter.string(from: userConfig.weekdayEvening)
        } else {
            morning.text = timeFormatter.string(from: userConfig.weekendMorning)
            evening.text = timeFormatter.string(from: userConfig.weekendEvening)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bag = DisposeBag()
        let delegate = UIApplication.shared.delegate as! AppDelegate

        updateLabels()
        updateLastNight()
        delegate.tonight
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateLastNight()
            }).disposed(by: bag)
        
        delegate.audioService
            .observer
            .running
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateToggleLabel()
            }).disposed(by: bag)
        updateToggleLabel()
    }
    
    func updateLastNight() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var night = delegate.nightService.fetchOne(at: Date())
        if night?.longestSleepDuration ?? 0 == 0 { night = delegate.nightService.fetchOne(at: Date(timeIntervalSinceNow: -24 * 60 * 60)) }
        
        disruptionCount.text = String(format: NSLocalizedString("DisruptionCount",
                                                                tableName: "Main",
                                                                bundle: .main,
                                                                value: "%d skærmaktiveringer",
                                                                comment: ""),
                                      night?.disruptionCount ?? 0
        )
        longestSleepDuration.text = String(format: NSLocalizedString("LongestSleepDuration",
                                                                     tableName: "Main",
                                                                     bundle: .main,
                                                                     value: "%.0f:%02.0f længste skærmfri",
                                                                     comment: ""),
                                           ((night?.longestSleepDuration ?? 0) / 3600.0).rounded(.down),
                                           ((night?.longestSleepDuration ?? 0) / 60.0).truncatingRemainder(dividingBy: 60.0)
        )
        unrestDuration.text = String(format: NSLocalizedString("UnrestDuration",
                                                               tableName: "Main",
                                                               bundle: .main,
                                                               value: "%.0f skærmtid",
                                                               comment: ""),
                                     (night?.unrestDuration ?? 0) / 60.0
        )
    }
    
    func updateToggleLabel() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let service = delegate.audioService
        NSLog("toggle, recording \(service.recording)")
        if service.recording {
            toggleButton.setTitle("✕", for: .normal)
            toggleButton.tintColor = .red
        } else {
            toggleButton.setTitle("↺", for: .normal)
            toggleButton.tintColor = .green
        }
    }
    
    @IBAction func toggleRecord(_ sender: UIButton) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let audio = delegate.audioService
        NSLog("toggle, recording \(audio.recording)")
        if audio.recording {
            audio.stopRecording()
        } else {
            audio.startRecording()
            let ud = UserDefaults()
            ud.setValueFor(.paused, to: false)
            ud.synchronize()
        }
        updateToggleLabel()
    }
    
    @IBAction func pause() {
        let alert = UIAlertController(title: NSLocalizedString("PauseTitle",
                                                               tableName: "Tonight",
                                                               bundle: .main,
                                                               value: "Pause",
                                                               comment: ""),
                                      message: NSLocalizedString("PauseText",
                                                                 tableName: "Tonight",
                                                                 bundle: .main,
                                                                 value: "Stop al monitorering af søvnrytmer",
                                                                 comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("PauseAction",
                                                               tableName: "Tonight",
                                                               bundle: .main,
                                                               value: "Stop",
                                                               comment: ""),
                                      style: .destructive,
                                      handler: { action in
                                        let ud = UserDefaults()
                                        ud.setValueFor(.paused, to: true)
                                        ud.synchronize()
                                        let delegate = UIApplication.shared.delegate as! AppDelegate
                                        delegate.audioService.stopRecording()
                                        AudioObserver.removeNotifications()
                                        self.updateToggleLabel()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Continue",
                                                               tableName: "Tonight",
                                                               bundle: .main,
                                                               value: "Fortsæt",
                                                               comment: ""),
                                      style: .default,
                                      handler: { action in
                                        alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
