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

class DrawerContentViewController: UIViewController, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        searchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    // Table view delegates
    
    
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
    
    override func didReceiveMemoryWarning() {
        // do nothing
    }
}
