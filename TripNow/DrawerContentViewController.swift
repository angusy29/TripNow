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

class DrawerContentViewController: UIViewController, UISearchBarDelegate, PulleyDrawerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {
     @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var selectedStopName: UILabel!
    @IBOutlet weak var selectedStopParent: UILabel!
    @IBOutlet weak var selectedStopType: UILabel!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var helpLabel: UILabel!
    
    var selectedStop: Stop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        selectedStopName.isHidden = true
        selectedStopParent.isHidden = true
        selectedStopType.isHidden = true
        goButton.isHidden = true
        
        /*let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)*/
    }
    
    // Table View delegates
    /* Functions for UITableView */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let pulley = self.parent as? PulleyViewController {
            let contentDrawer = pulley.primaryContentViewController as? UINavigationController
            let vc = contentDrawer?.viewControllers[0] as? ViewController
            return (vc?.getStopsFound().count)!
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DrawerTableCell", for: indexPath) as! DrawerTableCell
        let row = indexPath.row
        var table: [Stop] = []
        
        if let pulley = self.parent as? PulleyViewController {
            let contentDrawer = pulley.primaryContentViewController as? UINavigationController
            let vc = contentDrawer?.viewControllers[0] as? ViewController
            table = (vc?.getStopsFound())!
        }
        
        cell.stopName?.text = table[row].getName()
        cell.stopParent?.text = (table[row].getParent()) + " " + (table[row].getID())
        cell.stopType?.text = String(describing: table[row].getDistance()) + "m" + "\u{00B7}" + (table[row].getType())
        cell.isUserInteractionEnabled = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*let vc = self.storyboard?.instantiateViewController(withIdentifier: "StopInfoViewController") as! StopInfoViewController

        if let drawer = self.parent as? PulleyViewController {
            let contentDrawer = drawer.primaryContentViewController as? UINavigationController
            let tempVC = contentDrawer?.viewControllers[0] as? ViewController
            let indexPath = tableView.indexPathForSelectedRow
            vc.stopObj = tempVC?.getStopsFound()[(indexPath?.row)!]
            contentDrawer?.pushViewController(vc, animated: true)
            drawer.setDrawerPosition(position: .closed)
            tableView.deselectRow(at: indexPath!, animated: true)
        }*/
        searchBar.resignFirstResponder()
        if let drawer = self.parent as? PulleyViewController {
            let contentDrawer = drawer.primaryContentViewController as? UINavigationController
            let vc = contentDrawer?.viewControllers[0] as? ViewController
            let indexPath = tableView.indexPathForSelectedRow
            
            let tempStop = vc?.getStopsFound()[(indexPath?.row)!]
            setSelectedStop(stop: tempStop)
            setLabels(name: (tempStop?.getName())!, parent: (tempStop?.getParent())!, id: (tempStop?.getID())!, distance: (tempStop?.getDistance())!, type: (tempStop?.getType())!)
            
            vc?.mapView.selectedAnnotations.removeAll()
            vc?.mapView.selectAnnotation((vc?.allAnnotations[(indexPath?.row)!])!, animated: true)
            
            drawer.setDrawerPosition(position: .partiallyRevealed)
            tableView.deselectRow(at: indexPath!, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let drawerVC = self.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .open, animated: true)
        }
        searchBar.resignFirstResponder()
    }
        
    // PulleyDrawer delegates
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 68 + bottomSafeArea
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 264 + bottomSafeArea
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
    
    /*
     * Makes GET request to TFNSW
     * Using /stop_finder API endpoint
     */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let guardSearchBarText = searchBar.text else { return }
        guard let searchBarText = guardSearchBarText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
        
        let url = "https://api.transport.nsw.gov.au/v1/tp/stop_finder?TfNSWSF=true&outputFormat=rapidJSON&type_sf=any&name_sf=" + searchBarText + "&coordOutputFormat=EPSG%3A4326&anyMaxSizeHitList=10&version=10.2.2.48"
        
        var stopFinderRequest = URLRequest(url: URL(string: url)!)
        stopFinderRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        stopFinderRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        let sem = DispatchSemaphore(value: 0)

        // get the closest stops
        URLSession.shared.dataTask(with: stopFinderRequest){(data: Data?,response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                print(resultJson!)
                
                sem.signal()
            } catch {
                print("Error -> \(error)")
            }
        }.resume()
        
        sem.wait()
        
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
    
    func getTableView() -> UITableView {
        return tableView
    }
    
    // UI setters
    func setLabels(name: String, parent: String, id: String, distance: Double, type: String) {
        helpLabel?.isHidden = true
        selectedStopName.isHidden = false
        selectedStopParent.isHidden = false
        selectedStopType.isHidden = false
        goButton.isHidden = false

        selectedStopName?.text = name
        selectedStopParent?.text = parent + " " + id
        selectedStopType?.text = String(describing: distance) + "m" + "\u{00B7}" + type
    }
    
    func setSelectedStop(stop: Stop?) {
        selectedStop = stop
    }
    
    @IBAction func goButtonOnClick(_ sender: Any) {
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
