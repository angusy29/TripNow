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
    let locationManager = CLLocationManager()
    var isLocationInitCentre = false            // have we set the initial centre position of the user?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        var request = URLRequest(url: URL(string: "https://api.transport.nsw.gov.au/v1/tp/coord?outputFormat=rapidJSON&coord=" + String(longitude) + "%3A" + String(latitude) + "%3AEPSG%3A4326&coordOutputFormat=EPSG%3A4326&inclFilter=1&type_1=GIS_POINT&radius_1=1000&type_2=BUS_POINT&radius_2=1000&type_3=POI_POINT&radius_3=1000&version=10.2.2.48")!)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("apikey 3VEunYsUS44g3bADCI6NnAGzLPfATBClAnmE", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request){(data: Data?,response: URLResponse?, error: Error?) -> Void in
            do {
                let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                let locations = resultJson?["locations"] as? [[String: Any]]
                
                // get the first 5 locations
                for i in 1...5 {
                    let coordinates = locations?[i]["coord"] as? NSArray
                    let latCoord = coordinates![0] as? Double
                    let longCoord = coordinates![1] as? Double
                
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latCoord!, longitude: longCoord!)
                    self.mapView.addAnnotation(annotation)
                }
            } catch {
                print("Error -> \(error)")
            }
        }.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

