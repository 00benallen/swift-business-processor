//
//  EventReader.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-06.
//

import Foundation

struct ShutdownData {
    var reason: String
}

class ShutdownEvent: Event {
    
    var uniqueEventId: String
    
    var eventData: ShutdownData
    
    init() {
        self.uniqueEventId = "1"
        self.eventData = ShutdownData(reason: "Woo")
    }


}

