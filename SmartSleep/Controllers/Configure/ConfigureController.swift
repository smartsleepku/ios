//
//  ConfigureController.swift
//  SmartSleep
//
//  Created by Anders Borch on 27/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

fileprivate let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

class ConfigureController: UIViewController {
    
    @IBOutlet weak var weekdayMorning: UILabel!
    @IBOutlet weak var weekdayEvening: UILabel!
    @IBOutlet weak var weekendMorning: UILabel!
    @IBOutlet weak var weekendEvening: UILabel!
    
    @IBAction func close() {
        if ConfigurationService.configuration == nil {
            ConfigurationService.configuration = ConfigurationService.defaultConfiguration
        }
        AttendeeService.registerForPushNotifications()
        performSegue(withIdentifier: "UnwindConfigure", sender: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let userConfig = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        weekdayMorning.text = timeFormatter.string(from: userConfig.weekdayMorning)
        weekdayEvening.text = timeFormatter.string(from: userConfig.weekdayEvening)
        weekendMorning.text = timeFormatter.string(from: userConfig.weekendMorning)
        weekendEvening.text = timeFormatter.string(from: userConfig.weekendEvening)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let pickerSegue = segue as? PickerSegue else { return }
        pickerSegue.configuration = PickerConfiguration(rawValue: segue.identifier!)
    }
    
    @IBAction func closePicker(segue: UIStoryboardSegue) {
        let picker = segue.source as! PickerController
        UIView.animate(withDuration: 0.3,
                       animations: {
                        picker.view.alpha = 0
                        picker.overlay?.alpha = 0
        }) { complete in
            guard complete else { return }
            picker.willMove(toParent: nil)
            picker.view.removeFromSuperview()
            picker.removeFromParent()
            picker.overlay?.removeFromSuperview()
        }
    }
}
