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
    var radiusOverlay: MKCircle!
    var userAnnotation: MKPointAnnotation!           // annotation the user can drag
    var isLocationInitCentre = false            // have we set the initial centre position of the user?

    // list of stops we found
    var stopsFound = [Stop]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // let latitude = -33.90961750180199
        // let longitude = 151.20722349056894
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        initUserLocation()
        
        refresh.setTitle("Search", for: UIControlState.normal)
        
        // self.navigationItem.title = "Quick search"
        
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
     * Removes the navigation bar when this view appears
     */
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    /*
     * Shows the navigation bar when this view disappears
     */
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
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
            // locationManager.requestAlwaysAuthorization()
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
        if (!isLocationInitCentre && CLLocationManager.locationServicesEnabled()) {
            user = User(coordinate: (manager.location?.coordinate)!, radius: 400)
            let start = CLLocationCoordinate2DMake(user.getLatitude(), user.getLongitude())
            let adjustedRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(start, 1000, 1000))
            mapView.setRegion(adjustedRegion, animated: false)
                
            // need to remove this overlay later if user's position changes
            radiusOverlay = MKCircle(center: user.getCoordinate(), radius: user.getRadius())
            mapView.add(radiusOverlay)
                
            /*userAnnotation = createAnnotation(latitude: (locationManager.location?.coordinate.latitude)!,
                                                longitude: (locationManager.location?.coordinate.longitude)!, title: "Search radius: " + String(user.getRadius()) + "m", subtitle: "")*/
            userAnnotation = MKPointAnnotation()
            userAnnotation.coordinate = CLLocationCoordinate2D(latitude: user.getLatitude(), longitude: user.getLongitude())
            userAnnotation.title = "Search radius: " + String(Int(user.getRadius())) + "m "
            self.mapView.addAnnotation(userAnnotation)
            
            isLocationInitCentre = true
        } else if (!isLocationInitCentre && !CLLocationManager.locationServicesEnabled()) {
            userAnnotation = MKPointAnnotation()
            userAnnotation.coordinate = CLLocationCoordinate2D(latitude: -33.865143, longitude: 151.2099)
            userAnnotation.title = "Search radius: 400m "
            self.mapView.addAnnotation(userAnnotation)
            
            isLocationInitCentre = true
        }
        
        user.setCoordinate(coordinate: (manager.location?.coordinate)!)
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
        
        if (annotation.isEqual(userAnnotation)) {
            annotationView.pinTintColor = UIColor.green
            annotationView.isDraggable = true
        }
        
        annotationView.animatesDrop = true
        
        return annotationView
    }
    
    /*
     * Gets called when a pin is dragged
     * Seems to get called 2-3 times in the whole process
     */
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        mapView.remove(radiusOverlay)
        createRadiusOverlay()
    }
    
    // Invoked on click refresh
    @IBAction func onRefresh(_ sender: UIButton) {
        self.stopsFound.removeAll()
        mapView.removeAnnotations(allAnnotations)
        allAnnotations.removeAll()
        
        // let latitude = (locationManager.location?.coordinate.latitude)!
        // let longitude = (locationManager.location?.coordinate.longitude)!
        
        let latitude = userAnnotation.coordinate.latitude
        let longitude = userAnnotation.coordinate.longitude
        
        self.getClosestStopRequest(longitude: longitude, latitude: latitude, radius: user.getRadius())
        // self.getDepartureRequest()
        
        for stop in stopsFound {
            let annotation = self.createAnnotation(latitude: stop.getLatitude(), longitude: stop.getLongitude(), title: stop.getParent() + " " + stop.getID(), subtitle: stop.getName())
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
                
                if (locations?.count == 0) {
                    return
                }
                
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
     * Callback for when radius slider changes
     */
    @IBAction func radiusSliderOnChange(_ sender: Any) {
        self.user.setRadius(radius: CLLocationDistance(radiusSlider.value))
        userAnnotation.title = "Search radius: " + String(Int(user.getRadius())) + "m "
        mapView.selectAnnotation(userAnnotation, animated: true)

        // change the overlay radius
        if (radiusOverlay != nil) {
            mapView.remove(radiusOverlay)
        }
        
        createRadiusOverlay()
    }
    
    @IBAction func onReleaseSliderInside(_ sender: Any) {
        mapView.deselectAnnotation(userAnnotation, animated: false)
    }
    
    @IBAction func onReleaseSliderOutside(_ sender: Any) {
        mapView.deselectAnnotation(userAnnotation, animated: false)
    }
    
    /*
     * Creates a red annotation point for the bus stops
     */
    func createAnnotation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String) -> MKAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }
    
    /*
     * Creates blue radius overlay around the user annotation
     */
    func createRadiusOverlay() {
        radiusOverlay = MKCircle(center: userAnnotation.coordinate, radius: user.getRadius())
        mapView.add(radiusOverlay)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

