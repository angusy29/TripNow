//
//  StopEvent.swift
//  TripNow
//
//  Created by Angus Yuen on 22/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import Foundation

import Foundation

/*
 * StopEvent
 * busNumber - Bus stopping for this event
 * departureTimePlanned - Time the bus was planned to leave
 * departureTimeEstimated - Real time the bus is planned to leave
 * occupancy - Real time, how full is the bus?
 */
class StopEvent {
    var busNumber: String
    var departureTimePlanned: Date
    var departureTimeEstimated: Date?
    var occupancy: String?
    
    // these are used for finding the shape_id
    var inboundOrOutbound: String?  // R (inbound) or H (outbound)
    var instance: String?       // i have no idea what this is
    
    init(busNumber: String, departureTimePlanned: Date, departureTimeEstimated: Date?, occupancy: String?,
         inboundOrOutbound: String, instance: String) {
        self.busNumber = busNumber
        self.departureTimePlanned = departureTimePlanned
        self.departureTimeEstimated = departureTimeEstimated
        self.occupancy = occupancy
        self.inboundOrOutbound = inboundOrOutbound
        self.instance = instance
    }
    
    public func getBusNumber() -> String {
        return self.busNumber
    }
    
    public func getDepartureTimePlanned() -> Date {
        return self.departureTimePlanned
    }
    
    public func getDepartureTimeEstimated() -> Date? {
        return self.departureTimeEstimated
    }
    
    public func getOccupancy() -> String? {
        return self.occupancy
    }
}
