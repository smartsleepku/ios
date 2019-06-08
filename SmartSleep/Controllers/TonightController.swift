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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bag = DisposeBag()
        let delegate = UIApplication.shared.delegate as! AppDelegate

        let userConfig = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday <= 6 {
            morning.text = timeFormatter.string(from: userConfig.weekdayMorning)
            evening.text = timeFormatter.string(from: userConfig.weekdayEvening)
        } else {
            morning.text = timeFormatter.string(from: userConfig.weekendMorning)
            evening.text = timeFormatter.string(from: userConfig.weekendEvening)
        }
        
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

    }
    
    private func updateLastNight() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let night = delegate.nightService.fetchOne(at: Date())
        
        disruptionCount.text = String(format: NSLocalizedString("DisruptionCount",
                                                                tableName: "Main",
                                                                bundle: .main,
                                                                value: "%d afbrydelser",
                                                                comment: ""),
                                      night?.disruptionCount ?? 0
        )
        longestSleepDuration.text = String(format: NSLocalizedString("LongestSleepDuration",
                                                                     tableName: "Main",
                                                                     bundle: .main,
                                                                     value: "%.0f:%02.0f længste søvn",
                                                                     comment: ""),
                                           ((night?.longestSleepDuration ?? 0) / 3600.0).rounded(.down),
                                           ((night?.longestSleepDuration ?? 0) / 60.0).truncatingRemainder(dividingBy: 60.0)
        )
        unrestDuration.text = String(format: NSLocalizedString("UnrestDuration",
                                                               tableName: "Main",
                                                               bundle: .main,
                                                               value: "%.0f minutters uro",
                                                               comment: ""),
                                     (night?.unrestDuration ?? 0) / 60.0
        )
    }
    
    @IBAction func disclaimer() {
        let alert = UIAlertController(title: NSLocalizedString("DisclaimerTitle",
                                                               tableName: "Main",
                                                               bundle: .main,
                                                               value: "Overrasket over tallene?",
                                                               comment: ""),
                                      message: NSLocalizedString("DisclaimerText",
                                                                 tableName: "Main",
                                                                 bundle: .main,
                                                                 value: "Søvneksperimentet er et forskningsprojekt og vi arbejer konstant " +
                                        "på at forbedre vores resultater. I starten kan du nok forvente at tallene for din søvnrytme vil " +
                                        "ændre sig en hel del. Bare rolig, efterhånden som vi lærer mere og mere vil tallene blive mere og mere præcise.",
                                                                 comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok",
                                                               tableName: "Main",
                                                               bundle: .main,
                                                               value: "Ok",
                                                               comment: ""),
                                      style: .default,
                                      handler: { _ in
                                        alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
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
        let service = delegate.audioService
        print("toggle, recording \(service.recording)")
        if service.recording {
            service.stopRecording()
        } else {
            service.startRecording()
        }
        updateToggleLabel()
    }
}
