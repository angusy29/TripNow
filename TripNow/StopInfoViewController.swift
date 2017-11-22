//
//  StopInfoViewController.swift
//  TripNow
//
//  Created by Angus Yuen on 22/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import MapKit
import UIKit

class StopInfoViewController: UIViewController, UINavigationBarDelegate {
    
    var stopObj: Stop!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Stop info view controller")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
