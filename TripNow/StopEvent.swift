//
//  StopEvent.swift
//  TripNow
//
//  Created by Angus Yuen on 22/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import Foundation

import Foundation

class StopEvent {
    var busNumber: String
    var origin: String
    var destination: String
    var description: String
    var departureTimePlanned: Date
    var departureTimeEstimated: Date?
    // var occupancy: String
    
    init(busNumber: String, origin: String, destination: String, description: String, departureTimePlanned: Date, departureTimeEstimated: Date?) {
        self.busNumber = busNumber
        self.origin = origin
        self.destination = destination
        self.description = description
        self.departureTimePlanned = departureTimePlanned
        self.departureTimeEstimated = departureTimeEstimated
    }
    
    public func getBusNumber() -> String {
        return self.busNumber
    }
    
    public func getOrigin() -> String {
        return self.origin
    }
    
    public func getDestination() -> String {
        return self.destination
    }
    
    public func getDepartureTimePlanned() -> Date {
        return self.departureTimePlanned
    }
    
}
