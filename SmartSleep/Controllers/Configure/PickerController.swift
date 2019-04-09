//
//  PickerController.swift
//  SmartSleep
//
//  Created by Anders Borch on 01/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class PickerController: UIViewController {
    
    var overlay: UIView?
    var configuration: PickerConfiguration?
    @IBOutlet weak var timeOfDay: UILabel!
    @IBOutlet weak var daysOfWeek: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var picker: UIDatePicker!
    
    override func viewWillAppear(_ animated: Bool) {
        let userConfig: Configuration = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        switch configuration! {
        case .weekdayMorning:
            timeOfDay.text = "Hvornår står du op?"
            daysOfWeek.text = "hverdage"
            icon.image = UIImage(named: "morning")
            picker.date = userConfig.weekdayMorning
        case .weekdayEvening:
            timeOfDay.text = "Hvornår går du i seng?"
            daysOfWeek.text = "hverdage"
            icon.image = UIImage(named: "bedtime")
            picker.date = userConfig.weekdayEvening
        case .weekendMorning:
            timeOfDay.text = "Hvornår står du op?"
            daysOfWeek.text = "weekender"
            icon.image = UIImage(named: "morning")
            picker.date = userConfig.weekendMorning
        case .weekendEvening:
            timeOfDay.text = "Hvornår går du i seng?"
            daysOfWeek.text = "weekender"
            icon.image = UIImage(named: "bedtime")
            picker.date = userConfig.weekendEvening
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.viewWillAppear(true)
    }
    
    @IBAction func close() {
        var userConfig: Configuration = ConfigurationService.configuration ?? ConfigurationService.defaultConfiguration
        switch configuration! {
        case .weekdayMorning:
            userConfig.weekdayMorning = picker.date
        case .weekdayEvening:
            userConfig.weekdayEvening = picker.date
        case .weekendMorning:
            userConfig.weekendMorning = picker.date
        case .weekendEvening:
            userConfig.weekendEvening = picker.date
        }
        ConfigurationService.configuration = userConfig
        performSegue(withIdentifier: "UnwindPicker", sender: nil)
    }
}
