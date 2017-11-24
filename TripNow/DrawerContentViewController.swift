//
//  DrawerContentViewController.swift
//  TripNow
//
//  Created by Angus Yuen on 24/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import Foundation
import UIKit
import Pulley

class DrawerContentViewController: UIViewController, UISearchBarDelegate, PulleyDrawerViewControllerDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    // @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var stopName: UILabel!
    @IBOutlet weak var stopId: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var helpLabel: UILabel!
    
    var selectedStop: Stop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        stopName?.text = ""
        stopId?.text = ""
        distanceLabel?.text = ""
        typeLabel?.text = ""
        goButton.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    // UI setters
    func setLabels(name: String, id: String, distance: String, type: String) {
        helpLabel?.isHidden = true
        setStopName(name: name)
        setStopID(id: id)
        setDistanceLabel(distance: distance)
        setTypeLabel(type: type)
        goButton.isHidden = false
    }
    
    func setStopName(name: String) {
        stopName?.text = name
    }
    
    func setStopID(id: String) {
        stopId?.text = id
    }
    
    func setDistanceLabel(distance: String) {
        distanceLabel?.text = distance
    }
    
    func setTypeLabel(type: String) {
        let first = String(type.prefix(1)).capitalized
        let other = String(type.dropFirst())
        typeLabel?.text = first + other
    }
    
    func setSelectedStop(stop: Stop?) {
        selectedStop = stop
    }
        
    // PulleyDrawer delegates
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 52.0 + bottomSafeArea
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 164.0 + bottomSafeArea
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all
    }
    
    /*
     * Called each time the drawer position changes
     */
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if (drawer.drawerPosition == .open) {
            return
        }
        searchBar.resignFirstResponder()
    }
    
    
    // Search bar delegates
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let drawerVC = self.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .open, animated: true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        collapseVC()
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        collapseVC()
    }
    
    // Partially reveals the draewr
    // Hides the keyboard
    func collapseVC() {
        if let drawerVC = self.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .partiallyRevealed, animated: true)
        }
        searchBar.resignFirstResponder()
    }
    
    @IBAction func goButtonClicked(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "StopInfoViewController") as! StopInfoViewController
        vc.stopObj = selectedStop
        
        if let drawer = self.parent as? PulleyViewController {
            let contentDrawer = drawer.primaryContentViewController as? UINavigationController
            contentDrawer?.pushViewController(vc, animated: true)
            drawer.setDrawerPosition(position: .closed)
        }
    }
    
    override func didReceiveMemoryWarning() {
        // do nothing
    }
}
