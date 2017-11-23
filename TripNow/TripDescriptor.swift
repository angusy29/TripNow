//
//  TripDescriptor.swift
//  TripNow
//
//  Created by Angus Yuen on 23/11/17.
//  Copyright © 2017 Angus Yuen. All rights reserved.
//

import Foundation

/*
 * Describes a particular trip
 * A stop is one of many stops within a trip from Origin to Destination
 *
 * TripDescriptor gives us the Origin, Destination and Description of the
 * trip of a stop within the trip
 */
class TripDescriptor {
    var origin: String
    var destination: String
    var description: String
    var parent: String
    
    init(origin: String, destination: String, description: String, parent: String) {
        self.origin = origin
        self.destination = destination
        self.description = description
        self.parent = parent
    }
    
    public func getOrigin() -> String {
        return self.origin
    }
    
    public func getDestination() -> String {
        return self.destination
    }
    
    public func getDescription() -> String {
        return self.description
    }
    
    public func getParent() -> String {
        return parent
    }
}
