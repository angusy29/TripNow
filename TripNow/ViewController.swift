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
    // UI elements
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var refresh: UIButton!
    @IBOutlet weak var radiusSlider: UISlider!
    
    let locationManager = CLLocationManager()
    var allAnnotations = [MKAnnotation]()

    // usr related variables
    var user: User!
    var userRadiusOverlay: MKCircle!
    var isLocationInitCentre = false            // have we set the initial centre position of the user?

    // list of stops we found
    var stopsFound = [Stop]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh.setTitle("Search", for: UIControlState.normal)
        
        // let latitude = -33.90961750180199
        // let longitude = 151.20722349056894
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        initUserLocation()
        
        self.navigationItem.title = "Quick search"
        
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
    
    /*
     * Initialize the user's location
     * Obtains authorization from the user
     * And updates their location on the map
     */
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
    
    /*
     * Built in locationManager function which is continuously called
     * whenever new data is received
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // this should be invoked on the first time application is opened
        if (!isLocationInitCentre) {
            user = User(coordinate: (manager.location?.coordinate)!, radius: 400)
            let start = CLLocationCoordinate2DMake(user.getLatitude(), user.getLongitude())
            let adjustedRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(start, 1000, 1000))
            mapView.setRegion(adjustedRegion, animated: false)
            
            // need to remove this overlay later if user's position changes
            userRadiusOverlay = MKCircle(center: user.getCoordinate(), radius: user.getRadius())
            mapView.add(userRadiusOverlay)
            
            isLocationInitCentre = true
        } else {
            let newLatitude = (manager.location?.coordinate.latitude)!
            let newLongitude = (manager.location?.coordinate.longitude)!
            let epsilon = 0.5
            
            if (fabs(newLatitude - user.getLatitude()) <= epsilon && fabs(newLongitude - user.getLongitude()) <= epsilon) {
                return
            }
            
            user.setCoordinate(coordinate: (manager.location?.coordinate)!)
        }
    }
    
    /*
     * Callback to render the actual radius overlay
     */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
        circleRenderer.strokeColor = UIColor.blue
        circleRenderer.lineWidth = 1
        return circleRenderer
    }
    
    /*
     * Callback for when an annotation is tapped on
     * Brings them to the StopInfoViewController
     */
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "StopInfoViewController") as! StopInfoViewController
        var arr = view.annotation?.title!?.components(separatedBy: " ")
        let stopId = (arr?[(arr?.count)! - 1])!

        for stop in stopsFound {
            if stop.getID() == stopId {
                vc.stopObj = stop
                break
            }
        }
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /*
     * Gets called when a pin gets dropped
     * This makes the pointAnnotations render with the rightCalloutAccessory
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if (annotation is MKUserLocation) {
            return nil
        }
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton.init(type: UIButtonType.detailDisclosure)
        return annotationView
    }
    
    // Invoked on click refresh
    @IBAction func onRefresh(_ sender: UIButton) {
        self.stopsFound.removeAll()
        mapView.removeAnnotations(allAnnotations)
        allAnnotations.removeAll()
        
        let latitude = (locationManager.location?.coordinate.latitude)!
        let longitude = (locationManager.location?.coordinate.longitude)!
        
        self.getClosestStopRequest(longitude: longitude, latitude: latitude, radius: user.getRadius())
        // self.getDepartureRequest()
        
        for stop in stopsFound {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: stop.getLatitude(), longitude: stop.getLongitude())
            annotation.title = stop.getParent() + " " + stop.getID()
            annotation.subtitle = stop.getName()
            // annotation.subtitle = "Buses: "
            
            /*for bus in stop.getBuses() {
                annotation.subtitle = annotation.subtitle! + bus + " "
            }*/
            
            self.mapView.addAnnotation(annotation)
            allAnnotations.append(annotation)
        }
    }
    
    /*
     * Makes a GET request to /coord
     * Finds the 5 closest stops to the specified longitude and latitude
     */
    func getClosestStopRequest(longitude: Double, latitude: Double, radius: CLLocationDistance) {
        let sem = DispatchSemaphore(value: 0)
        
        // GET request to obtain the closest stops
        let closestStopsURL = "https://api.transport.nsw.gov.au/v1/tp/coord?outputFormat=rapidJSON&coord=" + String(longitude) + "%3A" + String(latitude) + "%3AEPSG%3A4326&coordOutputFormat=EPSG%3A4326&inclFilter=1&type_1=BUS_POINT&radius_1=" + String(user.getRadius()) + "&version=10.2.2.48"
        
        var closestStopsRequest = URLRequest(url: URL(string: closestStopsURL)!)
        closestStopsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        closestStopsRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        // get the closest stops
        URLSession.shared.dataTask(with: closestStopsRequest){(data: Data?,response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                let locations = resultJson?["locations"] as? [[String: Any]]
                
                for i in 0...((locations?.count)! - 1) {
                    if (i >= locations!.count) {
                        break
                    }
                    
                    let name = locations?[i]["name"] as? String
                    // let type = locations?[i]["type"] as? String
                    let parent = locations?[i]["parent"] as? [String: AnyObject]
                    let parentName = parent?["parent"]?["name"] as? String
                    let properties = locations?[i]["properties"] as? [String: AnyObject]
                    let stopId = properties?["STOPPOINT_GLOBAL_ID"] as? String
                    let coordinates = locations?[i]["coord"] as? NSArray
                    let latCoord = coordinates![0] as? Double
                    let longCoord = coordinates![1] as? Double
                    
                    // if the station we get exceeds user radius, we exit
                    if ((properties?["distance"])! as! Double > self.user.getRadius()) {
                        break
                    }
                    
                    let newStop = Stop(id: stopId!, name: name!, parent: parentName!, latitude: latCoord!, longitude: longCoord!)
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
        
        print("Today's date: " + todayDate)
        print("Current time: " + currentTime)
        
        // we will probably need to control the rate limit this fires
        // if it exceeds 5 per second, we're screwed
        for i in 0...(stopsFound.count - 1) {
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
    
    @IBAction func radiusSliderOnChange(_ sender: Any) {
        self.user.setRadius(radius: CLLocationDistance(radiusSlider.value))
        
        // change the overlay radius
        mapView.remove(userRadiusOverlay)
        userRadiusOverlay = MKCircle(center: user.getCoordinate(), radius: user.getRadius())
        mapView.add(userRadiusOverlay)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

