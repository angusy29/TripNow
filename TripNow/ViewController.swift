//
//  ViewController.swift
//  TripNow
//
//  Created by Angus Yuen on 17/07/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import MapKit
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var refresh: UIButton!
    let locationManager = CLLocationManager()
    var isLocationInitCentre = false            // have we set the initial centre position of the user?
    var stopsFound = [Stop]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh.setTitle("Find closest stops", for: UIControlState.normal)
        
        // let latitude = -33.90961750180199
        // let longitude = 151.20722349056894
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        initUserLocation()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        
        /*let gestureRecog = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecog:)))
        gestureRecog.delegate = self
        mapView.addGestureRecognizer(gestureRecog)*/
    }
    
    /*func handleTap(gestureRecog: UILongPressGestureRecognizer) {
        let location = gestureRecog.location(in: mapView)
        let coordinate = mapView.convert(location, to: mapView)
        
        print(coordinate)
    }*/
    
    func initUserLocation() {
        //Check for Location Services
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            
            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (!isLocationInitCentre) {
            let start = CLLocationCoordinate2DMake((manager.location?.coordinate.latitude)!, (manager.location?.coordinate.longitude)!)
            let adjustedRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(start, 1000, 1000))
            mapView.setRegion(adjustedRegion, animated: false)
            isLocationInitCentre = true
        }
    }
    
    // Invoked on click refresh
    @IBAction func onRefresh(_ sender: UIButton) {
        let latitude = (locationManager.location?.coordinate.latitude)!
        let longitude = (locationManager.location?.coordinate.longitude)!
        
        self.getClosestStopRequest(longitude: longitude, latitude: latitude)
        self.getDepartureRequest()
        
        for stop in stopsFound {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: stop.getLatitude(), longitude: stop.getLongitude())
            annotation.title = stop.getName()
            // annotation.subtitle = "Stop: " + stop.getID() + " Buses: "
            annotation.subtitle = "Buses: "
            
            for bus in stop.getBuses() {
                annotation.subtitle = annotation.subtitle! + bus + " "
            }
        
            self.mapView.addAnnotation(annotation)
        }
    }
    
    /*
     * Makes a GET request to /coord
     * Finds the 5 closest stops to the specified longitude and latitude
     */
    func getClosestStopRequest(longitude: Double, latitude: Double) {
        let sem = DispatchSemaphore(value: 0)
        
        // GET request to obtain the closest stops
        let closestStopsURL = "https://api.transport.nsw.gov.au/v1/tp/coord?outputFormat=rapidJSON&coord=" + String(longitude) + "%3A" + String(latitude) + "%3AEPSG%3A4326&coordOutputFormat=EPSG%3A4326&inclFilter=1&type_1=BUS_POINT&radius_1=1000&radius_2=1000&radius_3=1000&version=10.2.2.48"
        
        var closestStopsRequest = URLRequest(url: URL(string: closestStopsURL)!)
        closestStopsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        closestStopsRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        // get the closest stops
        URLSession.shared.dataTask(with: closestStopsRequest){(data: Data?,response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                let locations = resultJson?["locations"] as? [[String: Any]]
                
                // get the first 5 locations
                for i in 0...4 {
                    if (i >= locations!.count) {
                        break
                    }
                    
                    let name = locations?[i]["name"] as? String
                    // let type = locations?[i]["type"] as? String
                    let properties = locations?[i]["properties"] as? [String: AnyObject]
                    let stopId = properties?["STOPPOINT_GLOBAL_ID"] as? String
                    let coordinates = locations?[i]["coord"] as? NSArray
                    let latCoord = coordinates![0] as? Double
                    let longCoord = coordinates![1] as? Double
                    
                    let newStop = Stop(id: stopId!, name: name!, latitude: latCoord!, longitude: longCoord!)
                    self.stopsFound.append(newStop)
                }
                
                sem.signal()
            } catch {
                print("Error -> \(error)")
            }
        }.resume()
        
        sem.wait()
    }
    
    /*
     * Makes a GET request to /departure_mon 
     * Obtains the departure details for each of the stops in stopFound
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
        
        print("Today's date: " + todayDate)
        print("Current time: " + currentTime)
        
        for i in 0...4 {
            // used to get which buses pass which stop
            let departureURL = "https://api.transport.nsw.gov.au/v1/tp/departure_mon?TfNSWDM=true&outputFormat=rapidJSON&coordOutputFormat=EPSG%3A4326&mode=direct&type_dm=stop&name_dm=" + stopsFound[i].getID() + "&depArrMacro=dep&itdDate=" + todayDate + "&itdTime=" + currentTime + "&version=10.2.2.48"
        
            var departureRequest = URLRequest(url: URL(string: departureURL)!)
            departureRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            departureRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
            // get which buses pass the stop
            URLSession.shared.dataTask(with: departureRequest){(data: Data?, response: URLResponse?, error: Error?) -> Void in
                do {
                    let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                    print(self.stopsFound)
                    // print(resultJson!)
                
                    let stopEvents = resultJson?["stopEvents"] as? [[String: Any]]
                
                    for j in 0...(stopEvents!.count - 1) {
                        let transportation = stopEvents?[j]["transportation"] as? [String: AnyObject]
                        let busNumber = transportation?["disassembledName"] as? String
                    
                        if (!self.stopsFound[i].isBusExist(bus: busNumber!)) {
                            self.stopsFound[i].addBus(bus: busNumber!)
                        }
                    }
                    sem.signal()
                } catch {
                    print("Error -> \(error)")
                }
            }.resume()
            
            sem.wait()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

