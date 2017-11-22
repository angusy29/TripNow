//
//  Stop.swift
//  TripNow
//
//  Created by Angus Yuen on 21/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import Foundation

class Stop {
    var id: String
    var name: String
    var parent: String
    var latitude: Double
    var longitude: Double
    var buses: [String]
    
    init(id: String, name: String, parent: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.parent = parent
        self.latitude = latitude
        self.longitude = longitude
        self.buses = [String]()
    }
    
    public func addBus(bus: String) {
        buses.append(bus)
    }
    
    public func getID() -> String {
        return self.id
    }
    
    public func getName() -> String {
        return self.name
    }
    
    public func getParent() -> String {
        return self.parent
    }
    
    public func getLatitude() -> Double {
        return latitude
    }
    
    public func getLongitude() -> Double {
        return longitude
    }
    
    public func getBuses() -> [String] {
        return buses
    }
    
    /*
     * Returns true if the bus exists in list of buses
     * False otherwise
     */
    public func isBusExist(bus: String) -> Bool {
        return buses.contains(bus)
    }
}
