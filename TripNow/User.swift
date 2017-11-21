//
//  UserController.swift
//  TripNow
//
//  Created by Angus Yuen on 21/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import MapKit
import Foundation

class User {
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance     // radius around the user's location

    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.coordinate = coordinate
        self.radius = radius
    }
    
    public func setCoordinate(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    public func setRadius(radius: CLLocationDistance) {
        self.radius = radius
    }
    
    public func getCoordinate() -> CLLocationCoordinate2D {
        return self.coordinate
    }
    
    public func getLatitude() -> CLLocationDegrees {
        return self.coordinate.latitude
    }
    
    public func getLongitude() -> CLLocationDegrees {
        return self.coordinate.longitude
    }
    
    public func getRadius() -> CLLocationDistance {
        return self.radius
    }
}
