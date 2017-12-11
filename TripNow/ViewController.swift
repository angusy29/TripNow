//
//  ViewController.swift
//  TripNow
//
//  Created by Angus Yuen on 17/07/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import MapKit
import UIKit
import Pulley

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    // UI elements
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var refresh: UIButton!
    @IBOutlet weak var radiusSlider: UISlider!
    
    let locationManager = CLLocationManager()
    var allAnnotations = [MKAnnotation]()       // all annotations on the map

    // user related variables
    var user: User?
    var radiusOverlay: MKCircle?                // blue circle overlay around the userAnnotation
    var userAnnotation: MKPointAnnotation?      // annotation the user can drag
    var isLocationInitCentre = false            // have we set the initial centre position of the user?
    
    // list of stops we found
    var stopsFound = [Stop]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // let latitude = -33.90961750180199
        // let longitude = 151.20722349056894
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        
        initUserLocation()
        
        refresh.setTitle("Find stops", for: UIControlState.normal)
        
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
        if let drawer = self.parent?.parent as? PulleyViewController {
            drawer.setDrawerPosition(position: .collapsed)
        }
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
            // if coordinate is nil, default to centre of sydney
            let coordinate = manager.location?.coordinate ?? CLLocationCoordinate2D(latitude: -33.865143, longitude: 151.2099)
            user = User(coordinate: coordinate, radius: 400)
            
            guard let latitude = user?.getLatitude() else { return }
            guard let longitude = user?.getLongitude() else { return }
            guard let radius = user?.getRadius() else { return }
            
            let start = CLLocationCoordinate2DMake(latitude, longitude)
            let adjustedRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(start, 1000, 1000))
            mapView.setRegion(adjustedRegion, animated: false)
                
            // need to remove this overlay later if user's position changes
            radiusOverlay = MKCircle(center: coordinate, radius: radius)
            mapView.add(radiusOverlay!)
                
            userAnnotation = MKPointAnnotation()
            userAnnotation?.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            userAnnotation?.title = "Search radius: " + String(Int(radius)) + "m "

            if let userAnnotation = userAnnotation {
                self.mapView.addAnnotation(userAnnotation)
            }
            
            isLocationInitCentre = true
        } else if (!isLocationInitCentre) {
            // this is invoked on each subsequent time
            guard let latitude = user?.getLatitude() else { return }
            guard let longitude = user?.getLongitude() else { return }
            
            userAnnotation = MKPointAnnotation()
            userAnnotation?.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            userAnnotation?.title = "Search radius: 400m "
            
            guard let userAnnotation = userAnnotation else { return }
            self.mapView.addAnnotation(userAnnotation)
            
            isLocationInitCentre = true
        }
        
        guard let coordinate = user?.getCoordinate() else { return }
        user?.setCoordinate(coordinate: coordinate)
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
     * Callback for when an annotation callout is tapped on
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
        
        if let drawer = self.parent?.parent as? PulleyViewController {
            drawer.setDrawerPosition(position: .closed)
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /*
     * Callback for when an annotation custom view is clicked on
     */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var arr = view.annotation?.title!?.components(separatedBy: " ")
        let stopId = (arr?[(arr?.count)! - 1])!
        
        for stop in stopsFound {
            if stop.getID() == stopId {
                if let drawer = self.parent?.parent as? PulleyViewController {
                    drawer.setDrawerPosition(position: .partiallyRevealed)
                    let dvc = drawer.drawerContentViewController as? DrawerContentViewController
                    dvc?.setSelectedStop(stop: stop)
                    dvc?.setLabels(name: stop.getName(), parent: stop.getParent(), id: stop.getID(), distance: stop.getDistance(), type: stop.getType())
                }
                break
            }
        }
    }
    
    /*
     * Callback for when marker is deselected
     */
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let drawer = self.parent?.parent as? PulleyViewController {
            drawer.setDrawerPosition(position: .collapsed)
        }
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
        
        //let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
        if (annotation.isEqual(userAnnotation)) {
            let userAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
            userAnnotationView.pinTintColor = UIColor.green
            userAnnotationView.canShowCallout = true
            userAnnotationView.isDraggable = true
            userAnnotationView.animatesDrop = true
            return userAnnotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "marker")
            annotationView.canShowCallout = true
            annotationView.animatesDrop = true
            annotationView.rightCalloutAccessoryView = UIButton.init(type: UIButtonType.detailDisclosure)
            return annotationView
        }
    }
    
    /*
     * Gets called when a pin is dragged
     * Seems to get called 2-3 times in the whole process
     */
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        guard let radiusOverlay = radiusOverlay else { return }
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
        
        guard let latitude = userAnnotation?.coordinate.latitude else { return }
        guard let longitude = userAnnotation?.coordinate.longitude else { return }
        guard let radius = user?.getRadius() else { return }
        
        self.getClosestStopRequest(longitude: longitude, latitude: latitude, radius: radius)
        // self.getDepartureRequest()
        
        for stop in stopsFound {
            let annotation = self.createAnnotation(latitude: stop.getLatitude(), longitude: stop.getLongitude(), title: stop.getParent() + " " + stop.getID(), subtitle: stop.getName())
            
            self.mapView.addAnnotation(annotation)
            allAnnotations.append(annotation)
        }
        if let drawer = self.parent?.parent as? PulleyViewController {
            drawer.setDrawerPosition(position: .partiallyRevealed)
        
            if (stopsFound.count != 0) {
                let dvc = drawer.drawerContentViewController as? DrawerContentViewController

                dvc?.setSelectedStop(stop: stopsFound[0])
                dvc?.setLabels(name: stopsFound[0].getName(), parent: stopsFound[0].getParent(), id: stopsFound[0].getID(), distance: stopsFound[0].getDistance(), type: stopsFound[0].getType())
                dvc?.getTableView().reloadData()
            }
        }
    }
    
    /*
     * Makes a GET request to /coord
     * Finds the 5 closest stops to the specified longitude and latitude
     */
    func getClosestStopRequest(longitude: Double, latitude: Double, radius: CLLocationDistance) {
        guard let radius = user?.getRadius() else { return }
        
        // GET request to obtain the closest stops
        let closestStopsURL = "https://api.transport.nsw.gov.au/v1/tp/coord?outputFormat=rapidJSON&coord=" + String(longitude) + "%3A" + String(latitude) + "%3AEPSG%3A4326&coordOutputFormat=EPSG%3A4326&inclFilter=1&type_1=BUS_POINT&radius_1=" + String(radius) + "&version=10.2.2.48"
        
        var closestStopsRequest = URLRequest(url: URL(string: closestStopsURL)!)
        closestStopsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        closestStopsRequest.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        let sem = DispatchSemaphore(value: 0)

        // get the closest stops
        URLSession.shared.dataTask(with: closestStopsRequest){(data: Data?,response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                guard let locations = resultJson?["locations"] as? [[String: Any]] else { return }
                
                if locations.count == 0 {
                    sem.signal()
                    return
                }
                
                for i in 0...(locations.count - 1) {
                    if (i >= locations.count) {
                        break
                    }
                    
                    // these guards don't actually do anything, if it doesn't exist, it won't be nil because
                    // if the key doesn't exist in the JSON it's just []
                    guard let name = locations[i]["name"] as? String else { break }
                    guard let parent = locations[i]["parent"] as? [String: AnyObject] else { break }
                    guard let parentName = parent["parent"]?["name"] as? String else { break }
                    guard let type = parent["type"] as? String else { break }
                    guard let properties = locations[i]["properties"] as? [String: AnyObject] else { break }
                    guard let stopId = properties["STOPPOINT_GLOBAL_ID"] as? String else { return }
                    guard let coordinates = locations[i]["coord"] as? NSArray else { break }
                    guard let latCoord = coordinates[0] as? Double else { break }
                    guard let longCoord = coordinates[1] as? Double else { break }
                    guard let distance = properties["distance"] as? Double else { break }
                    
                    // if the station we get exceeds user radius, we exit
                    if (distance > radius) {
                        break
                    }
                    
                    let newStop = Stop(id: stopId, name: name, parent: parentName, latitude: latCoord, longitude: longCoord, distance: distance, type: type)
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
        self.user?.setRadius(radius: CLLocationDistance(radiusSlider.value))
        guard let radius = user?.getRadius() else { return }
        
        userAnnotation?.title = "Search radius: " + String(Int(radius)) + "m "
        if let userAnnotation = userAnnotation {
            mapView.selectAnnotation(userAnnotation, animated: true)
        }
        
        // change the overlay radius
        if let radiusOverlay = radiusOverlay {
            mapView.remove(radiusOverlay)
        }
        
        createRadiusOverlay()
    }
    
    /*
     * User annotation should stop showing callout if slider released
     */
    @IBAction func onReleaseSliderInside(_ sender: Any) {
        mapView.deselectAnnotation(userAnnotation, animated: false)
    }

    /*
     * User annotation should stop showing callout if slider released
     */
    @IBAction func onReleaseSliderOutside(_ sender: Any) {
        mapView.deselectAnnotation(userAnnotation, animated: false)
    }
    
    /*
     * Centre on the user's location, as well as the user annotation
     */
    @IBAction func onClickNearMe(_ sender: Any) {
        guard let userAnnotation = userAnnotation else { return }

        if (CLLocationManager.locationServicesEnabled()) {
            guard let coordinate = user?.getCoordinate() else { return }
            guard let radiusOverlay = radiusOverlay else { return }
            
            mapView.setCenter(coordinate, animated: true)
            mapView.removeAnnotation(userAnnotation)
            userAnnotation.coordinate = coordinate
            
            mapView.remove(radiusOverlay)
            createRadiusOverlay()
            
            mapView.addAnnotation(userAnnotation)
        } else {
            mapView.setCenter(userAnnotation.coordinate, animated: true)
        }
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
        guard let radius = user?.getRadius() else { return }
        guard let userAnnotation = userAnnotation else { return }
        
        radiusOverlay = MKCircle(center: userAnnotation.coordinate, radius: radius)

        guard let radiusOverlay = radiusOverlay else { return }
        mapView.add(radiusOverlay)
    }
    
    func getStopsFound() -> [Stop] {
        return self.stopsFound
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

