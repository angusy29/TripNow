//
//  CustomTableViewCell.swift
//  TripNow
//
//  Created by Angus Yuen on 23/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import Foundation
import UIKit

class CustomTableViewCell: UITableViewCell {
    @IBOutlet weak var waitTimeLabel: UILabel!
    @IBOutlet weak var timeTopLabel: UILabel!
    @IBOutlet weak var timeBottomLabel: UILabel!
    @IBOutlet weak var busCapImg1: UIImageView!
    @IBOutlet weak var busCapImg2: UIImageView!
    @IBOutlet weak var busCapImg3: UIImageView!
    @IBOutlet weak var parentLabel: UILabel!
    
    /*
     * Set the UI when there is no real time data
     */
    public func setUINoRealTime(time: String) {
        self.timeTopLabel?.text = time
        self.timeBottomLabel?.text = "Real-time data unavailable"
        self.busCapImg1?.image = UIImage(named: "customer-40-grey")
        self.busCapImg2?.image = UIImage(named: "customer-40-grey")
        self.busCapImg3?.image = UIImage(named: "customer-40-grey")
    }
    
    public func setWaitTimeLabel(time: Date, currentTime: Date) {
        var waitTime = time.timeIntervalSince(currentTime)
        let hours = Int(abs(waitTime) / 3600)
        let minutes = (Int(abs(waitTime) / 60) % 60)
        
        waitTime = abs(waitTime)
    
        if (hours == 0 && minutes == 0) {
            waitTimeLabel?.text = "Now"
            return
        }
    
        if (minutes > 90 || hours > 0) {
            // print as hours
            waitTimeLabel?.text = String(hours) + " hr"
            if (hours > 1) {
                waitTimeLabel?.text = (waitTimeLabel?.text)! + "s"
            }
        } else {
            // print as minutes
            waitTimeLabel?.text = String(minutes) + " min"
            if (minutes > 1) {
                waitTimeLabel?.text = (waitTimeLabel?.text)! + "s"
            }
        }
    }
}
