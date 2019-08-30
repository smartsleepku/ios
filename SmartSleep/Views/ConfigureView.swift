//
//  ConfigureView.swift
//  SmartSleep
//
//  Created by Anders Borch on 30/08/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class ConfigureView: UIView {
    @IBOutlet weak var weekendBedtime: UIImageView! {
        didSet {
            setImageTint(imageView: weekendBedtime)
        }
    }
    @IBOutlet weak var weekendMorning: UIImageView! {
        didSet {
            setImageTint(imageView: weekendMorning)
        }
    }
    @IBOutlet weak var weekdayBedtime: UIImageView! {
        didSet {
            setImageTint(imageView: weekdayBedtime)
        }
    }
    @IBOutlet weak var weekdayMorning: UIImageView! {
        didSet {
            setImageTint(imageView: weekdayMorning)
        }
    }

    func setImageTint(imageView: UIImageView) {
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
    }
}
