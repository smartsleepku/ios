//
//  HistoryDataSource.swift
//  SmartSleep
//
//  Created by Anders Borch on 07/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class HistoryDataSource: NSObject, UITableViewDataSource {
    
    lazy var nights: [Night] = {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.nightService.fetch().reversed()
    }()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NightCell", for: indexPath) as! HistoryCell
        cell.night = nights[indexPath.row]
        return cell
    }
    
    
}
