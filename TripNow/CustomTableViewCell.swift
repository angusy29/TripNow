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
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeTopLabel: UILabel!
    @IBOutlet weak var timeBottomLabel: UILabel!
    @IBOutlet weak var busCapLabel: UILabel!
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
        self.busCapLabel?.text = ""
        self.busCapImg1?.image = UIImage(named: "customer-40-grey")
        self.busCapImg2?.image = UIImage(named: "customer-40-grey")
        self.busCapImg3?.image = UIImage(named: "customer-40-grey")
    }
}
