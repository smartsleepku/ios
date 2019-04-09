//
//  MainView.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit

class MainView: UIView {
    @IBOutlet weak var splashCenter: NSLayoutConstraint!
    @IBOutlet weak var contentOffset: NSLayoutConstraint!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var updates: UIView!
    @IBOutlet weak var progress: UIProgressView!

    private lazy var link = { return CADisplayLink(target: self, selector: #selector(update)) }()
    private var start: Date?
    private var once = false
    
    func appearAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.start = Date()
            self.link.add(to: .current, forMode: .default)
        }
    }
    
    @objc func update() {
        guard start != nil else { return }
        
        // update splash view position
        let maxSplashOffset = bounds.height
        var offset = min(Date().timeIntervalSince(start!) * Double(maxSplashOffset), Double(maxSplashOffset / 3))
        splashCenter.constant = CGFloat(-offset)
        if offset == 200 { link.invalidate() }

        // update content position
        let maxContentOffset = content.bounds.height
        offset = max(Double(maxContentOffset) - Date().timeIntervalSince(start!) * Double(maxContentOffset * 3), 0)
        contentOffset.constant = CGFloat(offset)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard once == false else { return }
        once = true
        contentOffset.constant = content.bounds.height
    }
    
    func showUpdates(_ shown: Bool) {
        guard updates.isHidden == shown else { return }
        updates.alpha = updates.isHidden ? 0.0 : 1.0
        updates.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.updates.alpha = shown ? 1.0 : 0.0
        }) { _ in
            self.updates.isHidden = !shown
        }
    }
}
