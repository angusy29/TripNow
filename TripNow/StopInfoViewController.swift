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
import SwiftProtobuf

// with GTFS realtime timetable to plot routes
// figure out which endpoint i want
// STEPS
// eg. SMBSC009, to find out which one, I need to go into static agency.txt using operator ID
// to index into agency.txt
// the nth occurrence of the id gives us nth endpoint
// call the endpoint
// get octet stream and unzip it into multiple files
// trips.txt -> match route_id, get shape_id
// go into shapes.txt and get route
// long as process.... sigh
// more proper solution:
// use realtimeTripID, this is the tripID go to trips and get shapeID
class StopInfoViewController: UIViewController, UINavigationBarDelegate, EHHorizontalSelectionViewProtocol, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var isFetchingDataLabel: UILabel!
    
    var stopObj: Stop?
    weak var selectionList: EHHorizontalSelectionView!
    var busIdToStopEvent = [String: [StopEvent]]()
    var busIdToTripDesc = [String: TripDescriptor]()
    
    // the bus we tapped on in the horizontal list
    var selectedBus: String?        // contains actual bus numbers eg: 400
    var currTime: Date!
    var zoomMapInit = false
    var updateDepartureRequestTimer: Timer?
    var updateVehiclePositionTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.navigationItem.title = stopObj?.getName()
        
        self.navigationController?.navigationBar.isTranslucent = false
        // self.edgesForExtendedLayout = []
 
        let selectionList = EHHorizontalSelectionView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        selectionList.registerCell(with: EHHorizontalLineViewCell.self)
        selectionList.textColor = UIColor.blue
        selectionList.altTextColor = UIColor.black
        EHHorizontalLineViewCell.updateColorHeight(2)
        EHHorizontalLineViewCell.updateFont(UIFont.systemFont(ofSize: 14))
        EHHorizontalLineViewCell.updateFontMedium(UIFont.systemFont(ofSize: 15))
        EHHorizontalLineViewCell.updateTintColor(UIColor.blue)
        self.selectionList = selectionList
        
        view.addSubview(selectionList)
        self.mapView.delegate = self
        self.selectionList.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // init isFetchingDataLabel
        self.isFetchingDataLabel.layer.cornerRadius = 8
        self.isFetchingDataLabel.layer.masksToBounds = true
        
        // should really set the region to the bus closest to our current stop
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees((self.stopObj?.latitude)!), longitude: CLLocationDegrees((self.stopObj?.longitude)!))
        let adjustedRegion = self.mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(coordinate, 2500, 2500))
        self.mapView.setRegion(adjustedRegion, animated: false)
        
        // set an annotation for the bus stop we selected
        let annotation = MKPointAnnotation()
        annotation.title = stopObj?.getName()
        annotation.coordinate = coordinate
        DispatchQueue.main.async() {
            self.mapView.addAnnotation(annotation)
        }
        
        DispatchQueue.global().async {
            // do stuff in background concurrent thread
            self.getDepartureRequest()

            DispatchQueue.main.async() {
                // update UI
                self.selectionList.reloadData()
            }

            DispatchQueue.global().async() {
                self.getRealtimeVehiclePosition() // needs to be called after departure request, because selectedBus is nil until then
            }
            
            DispatchQueue.global().async() {
                self.getRoute()
            }
        }
        
        setUpdateInterval()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.updateDepartureRequestTimer?.invalidate()
        self.updateVehiclePositionTimer?.invalidate()
        
        // clean up mapview
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
    }
    
    /*
     * Calls getDepartureRequest and getRealtimeVehiclePosition at 30 second intervals
     */
    func setUpdateInterval() {
        DispatchQueue.main.async {
            self.updateDepartureRequestTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.getDepartureRequest), userInfo: nil, repeats: true)
        }
        
        let when = DispatchTime.now() + 1 // change to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.updateVehiclePositionTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.getRealtimeVehiclePosition), userInfo: nil, repeats: true)
        }
    }
    
    func getRoute() {
        DispatchQueue.main.async {
            self.isFetchingDataLabel.isHidden = false
        }
        
        // parse through agency.txt
        // get endpoint to call
        // call endpoint
        // get zip
        // unzip
        // parse through trip for realtimeID
        // get shapeID
        // find the coordinates
        
        // last solution
        // routes search for -370-
        // trips find :R or :H
        // get shape id
        // go into shapes.txt
        guard let selectedBus = self.selectedBus else { return }
        guard let events = busIdToStopEvent[selectedBus] else { return }
        guard let inboundOrOutbound = events[0].inboundOrOutbound else { return }
        guard let tripDesc = busIdToTripDesc[selectedBus] else { return }
        guard let operatorID = events[0].operatorId else { return }
        guard let realtimeTripID = events[0].realtimeTripId else { return }
        var allCoordinates = [CLLocationCoordinate2D]()

        // let url = "https://obscure-beach-92046.herokuapp.com/route/" + selectedBus + ":" + inboundOrOutbound + ":" + tripDesc.destination.replacingOccurrences(of: " ", with: "_")
        
        let url = "https://obscure-beach-92046.herokuapp.com/route_realtime/" + operatorID + "_" + selectedBus + ":" + realtimeTripID
        print(url)
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url)

            let sem = DispatchSemaphore(value: 0)
            
            URLSession.shared.dataTask(with: request){(data: Data?, response: URLResponse?, error: Error?) -> Void in
                do {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [Any]
                            let coordinates = resultJson as! [Dictionary<String, String>]
                            
                            for coordinate in coordinates {
                                let lat = Double(coordinate["latitude"]!)
                                let long = Double(coordinate["longitude"]!)
                                let location = CLLocationCoordinate2DMake(lat!, long!)
                                allCoordinates.append(location)
                            }
                        } else {
                            print("Fail")
                        }
                    }
                    sem.signal()
                } catch {
                    sem.signal()
                }
            }.resume()
            sem.wait()
        }
        
        DispatchQueue.main.async {
            let polyline = MKPolyline(coordinates: &allCoordinates, count: allCoordinates.count)
            self.mapView.add(polyline)
            self.isFetchingDataLabel.isHidden = true
        }
    }
    
    /*
     * Makes a GET request to https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses
     * Obtains real time vehicle position
     */
    @objc func getRealtimeVehiclePosition() {
        print("CALL")
        self.removeAnnotationsExceptStop()

        let url = "https://api.transport.nsw.gov.au/v1/gtfs/vehiclepos/buses"
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("text/plain", forHTTPHeaderField: "Accept")
        request.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        // should probably do this inside the URLSession to prevent wasting CPU cycles if the response fails
        guard let selectedBus = self.selectedBus else { return }
        let listOfStopEvents = self.busIdToStopEvent[selectedBus]
        var stopEvent: StopEvent? = nil
        if listOfStopEvents != nil {
            // find the first stop event which has real time data
            // so we can render the bus
            for i in 0...((listOfStopEvents?.count)! - 1) {
                if listOfStopEvents?[i].isRealTime != nil {
                    stopEvent = (listOfStopEvents?[i])!
                    break
                }
            }
        }
        
        let sem = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request){(data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Decoding.....")
                        let decodedData = try TransitRealtime_FeedMessage(serializedData: data!)
                        print("Decoded")
                        for entity in decodedData.entity {
                            let trip = entity.vehicle.trip
                            let position = entity.vehicle.position
                            
                            guard let operatorId = stopEvent?.operatorId else { continue }
                            guard let realtimeTripId = stopEvent?.realtimeTripId else { continue }
                            
                            if trip.routeID == operatorId + "_" + selectedBus && trip.tripID == realtimeTripId {
                                // add to the bus location to map
                                let annotation = MKPointAnnotation()
                                annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(position.latitude), longitude: CLLocationDegrees(position.longitude))
                                annotation.title = self.selectedBus
                                
                                DispatchQueue.main.async() {
                                    if !self.zoomMapInit {
                                        self.zoomMapInit = true
                                        let adjustedRegion = self.mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(annotation.coordinate, 2500, 2500))
                                        self.mapView.setRegion(adjustedRegion, animated: false)
                                    }
                                    self.mapView.addAnnotation(annotation)
                                }
                                break
                            }
                        }
                    }
                }
                sem.signal()
            } catch {
                print("CATCH")
                sem.signal()
            }
        }.resume()
        sem.wait()
    }
    
    /*
     * Makes a GET request to /departure_mon
     * Obtains the departure details for each of the stops in stopFound
     *
     * NOTE: It's quite clear if I ever want more than 1 person using the app
     * this function isn't scalable at all...
     * Will easily exceed API rate limit
     */
    @objc func getDepartureRequest() {
        self.busIdToStopEvent.removeAll()
        self.busIdToTripDesc.removeAll()
        
        let date = Date()
        let dateformatter = DateFormatter()
        dateformatter.timeZone = TimeZone(secondsFromGMT: 60 * 60 * 11)
        dateformatter.dateFormat = "yyyyMMdd"
        let timeformatter = DateFormatter()
        timeformatter.dateFormat = "HHmm"
        timeformatter.timeZone = TimeZone(secondsFromGMT: 60 * 60 * 11)
        let todayDate = dateformatter.string(from: date)    // in format yyyyMMdd
        let currentTime = timeformatter.string(from: date)  // in format hhmm
        currTime = date
        
        guard let id = stopObj?.getID() else { return }
        
        // used to get which buses pass which stop
        let departureURL = "https://api.transport.nsw.gov.au/v1/tp/departure_mon?TfNSWDM=true&outputFormat=rapidJSON&coordOutputFormat=EPSG%3A4326&mode=direct&type_dm=stop&name_dm=" + id + "&depArrMacro=dep&itdDate=" + todayDate + "&itdTime=" + currentTime + "&version=10.2.2.48"
        
        var departureRequest = URLRequest(url: URL(string: departureURL)!)
        departureRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        departureRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        let sem = DispatchSemaphore(value: 0)
        
        // get which buses pass the stop
        URLSession.shared.dataTask(with: departureRequest){(data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                print(resultJson!)
                
                let stopEvents = resultJson?["stopEvents"] as? [[String: Any]]
                
                let isoDateFormatter = ISO8601DateFormatter()
                
                if (stopEvents != nil) {
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

                        let tripProperties = stopEvents?[j]["properties"] as? [String: AnyObject]
                        let realtimeTripId = tripProperties != nil ? tripProperties?["RealtimeTripId"] as? String : nil
                        let transportOperator = transportation?["operator"] as? [String: AnyObject]
                        let operatorId = transportOperator != nil ? transportOperator?["id"] as? String : nil
                        
                        /*print(busNumber!)
                        print(originName!)
                        print(destinationName!)
                        print(description!)
                        print(departureTimePlanned!)*/
                        
                        var shapeSuffix = transportation?["id"] as? String
                        var inboundOrOutbound = ""      // either R (inbound) or H (outbound)
                        var instance = ""
                        if shapeSuffix != nil {
                            shapeSuffix = shapeSuffix?.components(separatedBy: .whitespaces)[1]
                            let tokens = shapeSuffix?.components(separatedBy: ":")
                            if tokens != nil {
                                inboundOrOutbound = tokens![1]
                                instance = tokens![2]
                            }
                        }
                        
                        let newStopEvent = StopEvent(busNumber: busNumber!, departureTimePlanned: departureTimePlanned!, departureTimeEstimated: departureTimeEstimated, occupancy: occupancy, realtimeTripId: realtimeTripId, operatorId: operatorId, isRealTime: isRealTime, inboundOrOutbound: inboundOrOutbound, instance: instance)
                        
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
                        
                        if (!(self.stopObj?.isBusExist(bus: busNumber!))!) {
                            self.stopObj?.addBus(bus: busNumber!)
                        }
                    }
                }
                sem.signal()
            } catch {
                print("Error -> \(error)")
            }
            }.resume()
        
        sem.wait()
        
        // initialize selected bus if nil
        if (self.selectedBus == nil && (self.stopObj?.getBuses().count)! > 0) {
            self.selectedBus = self.stopObj?.getBuses()[0]
            
            DispatchQueue.main.async {
                self.destinationLabel?.text = "Destination: " + (self.busIdToTripDesc[self.selectedBus!]?.destination)!
            }
        } else if (self.selectedBus == nil) {
            DispatchQueue.main.async {
                self.destinationLabel?.text = "No serving lines"
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Functions to implement for EHHorizontalSelectionViewProtocol */
    
    func numberOfItems(inHorizontalSelection hSelView: EHHorizontalSelectionView) -> UInt {
        guard let count = stopObj?.getBuses().count else { return 0 }
        return UInt(count)
    }
    
    func titleForItem(at index: UInt, forHorisontalSelection hSelView: EHHorizontalSelectionView) -> String? {
        return stopObj?.getBuses()[Int(index)]
    }
    
    /*
     * Callback for the selected item from horizontal view
     */
    func horizontalSelection(_ selectionView: EHHorizontalSelectionView, didSelectObjectAt index: UInt) {
        self.selectedBus = stopObj?.getBuses()[Int(index)]
        guard let selectedBus = self.selectedBus else { return }
        self.zoomMapInit = false
        self.destinationLabel?.text = "Destination: " + (self.busIdToTripDesc[selectedBus]?.destination)!
        self.tableView.reloadData()
        self.mapView.removeOverlays(self.mapView.overlays)
        self.removeAnnotationsExceptStop()
        
        DispatchQueue.global().async {
            self.getRoute()
        }
    }
    
    /* Functions for UITableView */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let selectedBus = self.selectedBus else { return 0 }
        return self.busIdToStopEvent[selectedBus]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let selectedBus = self.selectedBus else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        let row = indexPath.row
        let table = self.busIdToStopEvent[selectedBus]
        
        let sydneyTimeFormatter = DateFormatter()
        sydneyTimeFormatter.dateFormat = "h:mm a"
        sydneyTimeFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        
        /*let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM"
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        
        let date = dateFormatter.string(from: (table?[row].getDepartureTimePlanned())!)*/
        
        // cell.dateLabel?.text = String(describing: date)
        
        // if estimated time is not nil, it is real time
        if (table?[row].getDepartureTimeEstimated() != nil) {
            let timeDifference = table?[row].getDepartureTimePlanned().timeIntervalSince((table?[row].getDepartureTimeEstimated())!)
            // if timeDifference is negative, bus must be late, otherwise early
            var isEarly = Int(timeDifference!) < 0 ? "Late by" : "Early by"
            if (Int(timeDifference!) == 0) {
                isEarly = "On time"
            }
            
            let hours = Int(abs(timeDifference!)) / 3600
            let minutes = (Int(abs(timeDifference!)) / 60) % 60
            var lateTimeStr = ""
            if (hours != 0) {
                lateTimeStr = lateTimeStr + String(hours) + " hours"
            }
            
            if (minutes != 0) {
                lateTimeStr = lateTimeStr + String(minutes) + " minute"
                if (minutes > 1) {
                    lateTimeStr = lateTimeStr + "s"
                }
            }
           
            /*if (lateTimeStr != "") {
                lateTimeStr = lateTimeStr + "."
            }*/
            
            cell.timeTopLabel?.text = String(describing: (sydneyTimeFormatter.string(from: (table?[row].getDepartureTimeEstimated())!)))
            cell.timeBottomLabel?.text = String(describing: (sydneyTimeFormatter.string(from: (table?[row].getDepartureTimePlanned())!))) + " " + isEarly + " " + lateTimeStr
            
            if (table?[row].getOccupancy() == nil) {
                cell.busCapImg1?.image = UIImage(named: "customer-40-grey")
                cell.busCapImg2?.image = UIImage(named: "customer-40-grey")
                cell.busCapImg3?.image = UIImage(named: "customer-40-grey")
            } else if (table?[row].getOccupancy() == "MANY_SEATS") {
                cell.busCapImg1?.image = UIImage(named: "customer-40-green")
                cell.busCapImg2?.image = UIImage(named: "customer-40-grey")
                cell.busCapImg3?.image = UIImage(named: "customer-40-grey")
            } else if (table?[row].getOccupancy() == "FEW_SEATS") {
                cell.busCapImg1?.image = UIImage(named: "customer-40-yellow")
                cell.busCapImg2?.image = UIImage(named: "customer-40-yellow")
                cell.busCapImg3?.image = UIImage(named: "customer-40-grey")
            } else {
                cell.busCapImg1?.image = UIImage(named: "customer-40-red")
                cell.busCapImg2?.image = UIImage(named: "customer-40-red")
                cell.busCapImg3?.image = UIImage(named: "customer-40-red")
            }
            
            cell.setWaitTimeLabel(time: (table?[row].getDepartureTimeEstimated())!, currentTime: self.currTime)
        } else {
            // no real time
            cell.setUINoRealTime(time: sydneyTimeFormatter.string(from: (table?[row].getDepartureTimePlanned())!))
            cell.setWaitTimeLabel(time: (table?[row].getDepartureTimePlanned())!, currentTime: self.currTime)
        }
        
        cell.parentLabel?.text = self.busIdToTripDesc[selectedBus]?.getParent()
        
        return cell
    }
    
    /*
     * Gets called when a pin gets dropped
     * This makes the pointAnnotations render with the rightCalloutAccessory
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "busAnnotation")
        if annotation.coordinate.latitude == stopObj?.latitude && annotation.coordinate.longitude == stopObj?.longitude {
            // this is the bus stop
            annotationView.pinTintColor = UIColor.green
        } else {
            // these are the buses
            annotationView.pinTintColor = UIColor.red
        }
        annotationView.canShowCallout = true
        return annotationView
    }
    
    /*
     * Polyline mapview
     */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = UIColor.blue
        polylineRenderer.alpha = 0.7
        polylineRenderer.lineWidth = 4
        return polylineRenderer
    }
    
    /*
     * Removes all annotations from mapView except for the stopObj
     */
    func removeAnnotationsExceptStop() {
        for annotation in self.mapView.annotations {
            if annotation.coordinate.latitude != stopObj?.latitude && annotation.coordinate.longitude != stopObj?.longitude {
                self.mapView.removeAnnotation(annotation)
            }
        }
    }
}
