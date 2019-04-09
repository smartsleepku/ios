//
//  HistoryDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 07/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class HistoryDelegate: NSObject, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 94
    }
}
