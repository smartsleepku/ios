//
//  HistoryCell.swift
//  SmartSleep
//
//  Created by Anders Borch on 07/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

fileprivate let formatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d. MMMM"
    return dateFormatter
}()

class HistoryCell: UITableViewCell {
    @IBOutlet weak var disruptionCount: UILabel!
    @IBOutlet weak var longestSleepDuration: UILabel!
    @IBOutlet weak var unrestDuration: UILabel!
    @IBOutlet weak var date: UILabel!

    var night: Night? {
        didSet {
            date.text = formatter.string(from: night?.from ?? Date())
            disruptionCount.text = "\(night?.disruptionCount ?? 0)"
            longestSleepDuration.text = String(format: "%.0f:%02.0f",
                                               ((night?.longestSleepDuration ?? 0) / 3600.0).rounded(.down),
                                               ((night?.longestSleepDuration ?? 0) / 60.0).truncatingRemainder(dividingBy: 60.0)
            )
            unrestDuration.text = String(format: "%.0f",
                                         (night?.unrestDuration ?? 0) / 60.0
            )
        }
    }
}
