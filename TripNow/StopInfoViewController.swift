//
//  StopInfoViewController.swift
//  TripNow
//
//  Created by Angus Yuen on 22/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import MapKit
import UIKit
import EHHorizontalSelectionView

class StopInfoViewController: UIViewController, UINavigationBarDelegate, EHHorizontalSelectionViewProtocol, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var stopObj: Stop!
    var selectionList: EHHorizontalSelectionView!
    var busIdToStopEvent = [String: [StopEvent]]()
    var busIdToTripDesc = [String: TripDescriptor]()
    
    // the bus we tapped on in the horizontal list
    var selectedBus: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.navigationItem.title = stopObj.getName()
        
        self.navigationController?.navigationBar.isTranslucent = false
        // self.edgesForExtendedLayout = []
 
        let selectionList = EHHorizontalSelectionView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        selectionList.delegate = self
        selectionList.registerCell(with: EHHorizontalLineViewCell.self)
        selectionList.textColor = UIColor.blue
        selectionList.altTextColor = UIColor.black
        EHHorizontalLineViewCell.updateColorHeight(2)
        EHHorizontalLineViewCell.updateFont(UIFont.systemFont(ofSize: 14))
        EHHorizontalLineViewCell.updateFontMedium(UIFont.systemFont(ofSize: 15))
        EHHorizontalLineViewCell.updateTintColor(UIColor.blue)
        self.selectionList = selectionList
        
        view.addSubview(selectionList)
        
        getDepartureRequest()
        
    }
    
    /*
     * Makes a GET request to /departure_mon
     * Obtains the departure details for each of the stops in stopFound
     *
     * NOTE: It's quite clear if I ever want more than 1 person using the app
     * this function isn't scalable at all...
     * Will easily exceed API rate limit
     */
    func getDepartureRequest() {
        let sem = DispatchSemaphore(value: 0)
        let date = Date()
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyyMMdd"
        let timeformatter = DateFormatter()
        timeformatter.dateFormat = "hhmm"
        let todayDate = dateformatter.string(from: date)    // in format yyyyMMdd
        let currentTime = timeformatter.string(from: date)  // in format hhmm
        
        // used to get which buses pass which stop
        let departureURL = "https://api.transport.nsw.gov.au/v1/tp/departure_mon?TfNSWDM=true&outputFormat=rapidJSON&coordOutputFormat=EPSG%3A4326&mode=direct&type_dm=stop&name_dm=" + stopObj.getID() + "&depArrMacro=dep&itdDate=" + todayDate + "&itdTime=" + currentTime + "&version=10.2.2.48"
        
        var departureRequest = URLRequest(url: URL(string: departureURL)!)
        departureRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        departureRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        // get which buses pass the stop
        URLSession.shared.dataTask(with: departureRequest){(data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                // print(resultJson!)
                
                let stopEvents = resultJson?["stopEvents"] as? [[String: Any]]
                
                let isoDateFormatter = ISO8601DateFormatter()
                
                for j in 0...(stopEvents!.count - 1) {
                    let isRealTime = stopEvents?[j]["isRealtimeControlled"] as? Bool
                    let location = stopEvents?[j]["location"] as? [String: AnyObject]
                    let properties = location!["properties"] as? [String: AnyObject]
                    let occupancy = isRealTime == true ? properties?["occupancy"] as? String : nil
                    let parent = location?["parent"] as? [String: AnyObject]
                    let nestedParent = parent?["parent"] as? [String: AnyObject]
                    let parentName = nestedParent?["name"] as? String
                    let departureTimePlanned = isoDateFormatter.date(from: (stopEvents?[j]["departureTimePlanned"] as? String)!)
                    let departureTimeEstimated = isRealTime == true ? isoDateFormatter.date(from: (stopEvents?[j]["departureTimeEstimated"] as? String)!): nil
                    let transportation = stopEvents?[j]["transportation"] as? [String: AnyObject]
                    let busNumber = transportation?["number"] as? String
                    let description = transportation?["description"] as? String
                    let origin = transportation?["origin"] as? [String: AnyObject]
                    let destination = transportation?["destination"] as? [String: AnyObject]
                    let originName = origin?["name"] as? String
                    let destinationName = destination?["name"] as? String
                    
                    // initialize selected bus if nil
                    if (self.selectedBus == nil) {
                        self.selectedBus = busNumber
                    }
                    
                    /*print(busNumber!)
                    print(originName!)
                    print(destinationName!)
                    print(description!)
                    print(departureTimePlanned!)*/
                    
                    let newStopEvent = StopEvent(busNumber: busNumber!, departureTimePlanned: departureTimePlanned!, departureTimeEstimated: departureTimeEstimated, occupancy: occupancy)
                    
                    // if the busId isn't in the map yet, we need to create a new array for it in the dictionary
                    if (self.busIdToStopEvent[busNumber!] == nil) {
                        var newBus = [StopEvent]()
                        newBus.append(newStopEvent)
                        self.busIdToStopEvent[busNumber!] = newBus
                        self.busIdToTripDesc[busNumber!] = TripDescriptor(origin: originName!, destination: destinationName!, description: description!, parent: parentName!)
                    } else {
                        // otherwise just append to the busNumber's vector
                        (self.busIdToStopEvent[busNumber!])?.append(newStopEvent)
                    }
                    
                    if (!self.stopObj.isBusExist(bus: busNumber!)) {
                        self.stopObj.addBus(bus: busNumber!)
                    }
                }
                sem.signal()
            } catch {
                print("Error -> \(error)")
            }
            }.resume()
        
        sem.wait()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Functions to implement for EHHorizontalSelectionViewProtocol */
    
    func numberOfItems(inHorizontalSelection hSelView: EHHorizontalSelectionView) -> UInt {
        return UInt(stopObj.getBuses().count)
    }
    
    func titleForItem(at index: UInt, forHorisontalSelection hSelView: EHHorizontalSelectionView) -> String? {
        return stopObj.getBuses()[Int(index)]
    }
    
    /*
     * Callback for the selected item from horizontal view
     */
    func horizontalSelection(_ selectionView: EHHorizontalSelectionView, didSelectObjectAt index: UInt) {
        self.selectedBus = stopObj.getBuses()[Int(index)]
        self.tableView.reloadData()
    }
    
    /* Functions for UITableView */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.busIdToStopEvent[self.selectedBus]?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        let row = indexPath.row
        let table = self.busIdToStopEvent[self.selectedBus]
        
        let sydneyTimeFormatter = DateFormatter()
        sydneyTimeFormatter.dateFormat = "HH:mm"
        sydneyTimeFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM"
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        
        let date = dateFormatter.string(from: (table?[row].getDepartureTimePlanned())!)
        
        cell.dateLabel?.text = String(describing: date)
        
        // if estimated time is not nil, it is real time
        if (table?[row].getDepartureTimeEstimated() != nil) {
            cell.timeTopLabel?.text = String(describing: (sydneyTimeFormatter.string(from: (table?[row].getDepartureTimeEstimated())!)))
            cell.timeBottomLabel?.text = String(describing: (sydneyTimeFormatter.string(from: (table?[row].getDepartureTimePlanned())!)))
            cell.busCapLabel?.text = table?[row].getOccupancy() != nil ? table?[row].getOccupancy() : ""
        } else {
            // no real time
            cell.timeTopLabel?.text = String(describing: (sydneyTimeFormatter.string(from: (table?[row].getDepartureTimePlanned())!)))
            cell.timeBottomLabel?.text = "Real-time data unavailable"
            cell.busCapLabel?.text = ""
        }
        
        return cell
    }
}
